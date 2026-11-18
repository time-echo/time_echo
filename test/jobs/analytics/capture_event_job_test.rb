# frozen_string_literal: true

require "test_helper"

class Analytics::CaptureEventJobTest < ActiveSupport::TestCase
  test "delegates capture action to PosthogService.capture_now" do
    captured_args = nil
    original = Analytics::PosthogService.method(:capture_now)

    Analytics::PosthogService.define_singleton_method(:capture_now) do |**kwargs|
      captured_args = kwargs
      true
    end

    Analytics::CaptureEventJob.perform_now(
      action_type: "capture",
      event: "letter_scheduled",
      distinct_id: "usr_12345",
      properties: { "letter_id" => "99" },
      occurred_at: "2026-11-17T00:00:00Z"
    )

    assert_not_nil captured_args
    assert_equal "letter_scheduled", captured_args[:event]
    assert_equal "usr_12345", captured_args[:distinct_id]
    assert_equal({ "letter_id" => "99" }, captured_args[:properties])
  ensure
    Analytics::PosthogService.define_singleton_method(:capture_now, original.to_proc)
  end

  test "delegates identify action to PosthogService.identify_now" do
    identified_args = nil
    original = Analytics::PosthogService.method(:identify_now)

    Analytics::PosthogService.define_singleton_method(:identify_now) do |**kwargs|
      identified_args = kwargs
      true
    end

    Analytics::CaptureEventJob.perform_now(
      action_type: "identify",
      distinct_id: "usr_12345",
      properties: { "locale" => "es" }
    )

    assert_not_nil identified_args
    assert_equal "usr_12345", identified_args[:distinct_id]
    assert_equal({ "locale" => "es" }, identified_args[:properties])
  ensure
    Analytics::PosthogService.define_singleton_method(:identify_now, original.to_proc)
  end
end
