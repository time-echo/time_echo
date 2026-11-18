# frozen_string_literal: true

require "test_helper"

class Analytics::PosthogServiceTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  class FakePosthogClient
    attr_reader :captured_events, :identified_users

    def initialize(raise_error: false)
      @captured_events = []
      @identified_users = []
      @raise_error = raise_error
    end

    def capture(payload)
      raise StandardError, "PostHog network outage" if @raise_error

      @captured_events << payload
    end

    def identify(payload)
      raise StandardError, "PostHog network outage" if @raise_error

      @identified_users << payload
    end
  end

  setup do
    @original_env = {
      "ANALYTICS_ENABLED" => ENV["ANALYTICS_ENABLED"],
      "ANALYTICS_ENVIRONMENT" => ENV["ANALYTICS_ENVIRONMENT"],
      "ANALYTICS_FORCE_ENABLED" => ENV["ANALYTICS_FORCE_ENABLED"],
      "POSTHOG_API_KEY" => ENV["POSTHOG_API_KEY"],
      "POSTHOG_HOST" => ENV["POSTHOG_HOST"]
    }
    Analytics::PosthogService.reset_client!
  end

  teardown do
    @original_env.each do |key, val|
      if val.nil?
        ENV.delete(key)
      else
        ENV[key] = val
      end
    end
    Analytics::PosthogService.reset_client!
  end

  test "UserIdentifier generates deterministic pseudonymous ID without exposing email" do
    id1 = Analytics::UserIdentifier.for("Reader@Example.com ")
    id2 = Analytics::UserIdentifier.for("reader@example.com")

    assert_equal id1, id2
    assert id1.start_with?("usr_")
    assert_equal 36, id1.length
    assert_not_includes id1, "reader"
    assert_not_includes id1, "example.com"
    assert_nil Analytics::UserIdentifier.for("   ")
  end

  test "disabled by default in development and test environments" do
    ENV["POSTHOG_API_KEY"] = "phc_test_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "development"
    ENV.delete("ANALYTICS_FORCE_ENABLED")

    assert_not Analytics::PosthogService.enabled?
    assert_no_enqueued_jobs only: Analytics::CaptureEventJob do
      result = Analytics::PosthogService.track(
        event: "letter_scheduled",
        email: "user@example.com",
        properties: { letter_id: "1" }
      )
      assert_equal false, result
    end
  end

  test "enabled in staging and production when POSTHOG_API_KEY is configured" do
    ENV["POSTHOG_API_KEY"] = "phc_staging_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "staging"
    ENV["ANALYTICS_ENABLED"] = "true"

    assert Analytics::PosthogService.enabled?

    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    assert Analytics::PosthogService.enabled?

    ENV["POSTHOG_API_KEY"] = ""
    assert_not Analytics::PosthogService.enabled?
  end

  test "sanitizes sensitive keys and redacts embedded email strings" do
    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    raw = {
      letter_id: "42",
      email: "secret@example.com",
      title: "Private letter title",
      content: "Private letter body",
      token: "tok_secret",
      prediction: "Secret prediction",
      reality: "Secret reality",
      note: "Contact me at leak@example.com for details",
      nested: {
        user_email: "nested@example.com",
        safe_count: 3
      }
    }

    sanitized = Analytics::PosthogService.sanitize_properties(raw)

    assert_equal "42", sanitized["letter_id"]
    assert_equal "production", sanitized["environment"]
    assert_equal "backend", sanitized["source"]
    assert_equal "Contact me at [REDACTED] for details", sanitized["note"]
    assert_equal({ "safe_count" => 3, "environment" => "production" }, sanitized["nested"])

    %w[email title content token prediction reality].each do |forbidden|
      assert_not sanitized.key?(forbidden), "Expected #{forbidden} to be stripped"
    end
  end

  test "enqueues CaptureEventJob and sends sanitized event to PostHog client" do
    ENV["POSTHOG_API_KEY"] = "phc_prod_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    fake_client = FakePosthogClient.new
    Analytics::PosthogService.client = fake_client

    assert_enqueued_with(job: Analytics::CaptureEventJob) do
      Analytics::PosthogService.track(
        event: "letter_scheduled",
        email: "writer@example.com",
        properties: {
          letter_id: "101",
          email: "writer@example.com",
          content: "Should never be sent",
          has_stamp: true
        }
      )
    end

    perform_enqueued_jobs only: Analytics::CaptureEventJob

    assert_equal 1, fake_client.captured_events.size
    captured = fake_client.captured_events.first
    assert_equal Analytics::UserIdentifier.for("writer@example.com"), captured[:distinct_id]
    assert_equal "letter_scheduled", captured[:event]
    assert_equal "101", captured[:properties]["letter_id"]
    assert_equal true, captured[:properties]["has_stamp"]
    assert_nil captured[:properties]["email"]
    assert_nil captured[:properties]["content"]
  end

  test "analytics failures never raise or break business operations" do
    ENV["POSTHOG_API_KEY"] = "phc_prod_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    Analytics::PosthogService.client = FakePosthogClient.new(raise_error: true)

    assert_nothing_raised do
      result = Analytics::PosthogService.track(
        event: "letter_scheduled",
        email: "writer@example.com",
        properties: { letter_id: "1" },
        async: false
      )
      assert_equal false, result
    end

    result = Letters::CreateService.call(
      params: {
        title: "Resilient Letter",
        email: "resilient@example.com",
        content: "Writing a long enough letter to my future self so validation passes cleanly in the test.",
        deliver_at: 1.year.from_now,
        happiness_level: 8,
        anxiety_level: 3,
        motivation_level: 9
      }
    )
    assert result.success?
  end

  test "AuthenticateTokenService tracks user_signed_up on first login and user_logged_in on subsequent logins" do
    ENV["POSTHOG_API_KEY"] = "phc_prod_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    fake_client = FakePosthogClient.new
    Analytics::PosthogService.client = fake_client

    email = "brand_new_user@example.com"
    first_token = SessionToken.create!(email: email)

    perform_enqueued_jobs only: Analytics::CaptureEventJob do
      first_result = Auth::AuthenticateTokenService.call(token: first_token.token)
      assert first_result.success?
      assert_equal true, first_result.value[:is_new_user]
      assert_equal Analytics::UserIdentifier.for(email), first_result.value[:user_id]
    end

    events = fake_client.captured_events.map { |e| e[:event] }
    assert_includes events, "user_signed_up"
    assert_not_includes events, "user_logged_in"

    fake_client.captured_events.clear
    second_token = SessionToken.create!(email: email)

    perform_enqueued_jobs only: Analytics::CaptureEventJob do
      second_result = Auth::AuthenticateTokenService.call(token: second_token.token)
      assert second_result.success?
      assert_equal false, second_result.value[:is_new_user]
    end

    second_events = fake_client.captured_events.map { |e| e[:event] }
    assert_includes second_events, "user_logged_in"
    assert_not_includes second_events, "user_signed_up"
  end

  test "tracks letter_scheduled, letter_viewed, letter_saved, and letter_shared without sensitive data" do
    ENV["POSTHOG_API_KEY"] = "phc_prod_key"
    ENV["ANALYTICS_ENVIRONMENT"] = "production"
    fake_client = FakePosthogClient.new
    Analytics::PosthogService.client = fake_client

    email = "capsule_owner@example.com"
    letter = nil

    perform_enqueued_jobs only: Analytics::CaptureEventJob do
      create_res = Letters::CreateService.call(
        params: {
          title: "Confidential Title",
          email: email,
          content: "Confidential letter body with at least ten words and eighty characters to pass validation.",
          deliver_at: 1.year.from_now,
          happiness_level: 7,
          anxiety_level: 4,
          motivation_level: 8,
          prediction_city: "Lisbon"
        }
      )
      assert create_res.success?
      letter = create_res.letter

      access_res = Letters::AccessService.call(letter.id, email)
      assert access_res.success?

      letter.update_columns(status: "delivered", delivered_at: Time.current)
      pred = letter.predictions.first

      update_res = Letters::UpdatePredictionsService.call(
        letter.id,
        {
          reveal_happiness: 9,
          reveal_anxiety: 2,
          reveal_motivation: 9,
          is_wax_broken: true,
          predictions: [ { id: pred.id, reality: "Living in Porto", matched: true } ]
        },
        email
      )
      assert update_res.success?

      Analytics::PosthogService.track_letter_shared(
        letter: letter,
        actor_email: email,
        share_method: "clipboard"
      )
    end

    tracked_names = fake_client.captured_events.map { |e| e[:event] }
    assert_equal %w[letter_scheduled letter_viewed letter_saved letter_shared], tracked_names

    fake_client.captured_events.each do |event_payload|
      assert_equal Analytics::UserIdentifier.for(email), event_payload[:distinct_id]
      serialized = event_payload.to_json
      assert_not_includes serialized, email
      assert_not_includes serialized, "Confidential Title"
      assert_not_includes serialized, "Confidential letter body"
      assert_not_includes serialized, "Lisbon"
      assert_not_includes serialized, "Living in Porto"
    end
  end
end
