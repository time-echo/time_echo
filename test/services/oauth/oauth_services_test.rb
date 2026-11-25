# frozen_string_literal: true

require "test_helper"

class Oauth::OauthServicesTest < ActiveSupport::TestCase
  class FakeProvider
    def initialize(profile: nil, error: nil)
      @profile = profile
      @error = error
    end

    def authorization_url(state:, code_challenge:, redirect_uri:)
      "https://provider.example/auth?state=#{state}&code_challenge=#{code_challenge}&redirect_uri=#{CGI.escape(redirect_uri)}"
    end

    def fetch_profile(code:, code_verifier:, redirect_uri:)
      raise @error if @error

      @profile
    end
  end

  def with_fake_provider(fake)
    original = Oauth::ProviderRegistry.method(:fetch)
    Oauth::ProviderRegistry.define_singleton_method(:fetch) { |_name| fake }
    yield
  ensure
    Oauth::ProviderRegistry.define_singleton_method(:fetch, original)
  end

  test "creates new user and identity on first social login" do
    raw_state, = OauthState.create_for!(provider: "google")
    fake = FakeProvider.new(profile: { uid: "g-001", email: "new_social@example.com", email_verified: true, name: "New" })

    result = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "auth-code", state: raw_state)
    end

    assert result.success?
    assert_equal "new_social@example.com", result.value[:email]
    assert_equal true, result.value[:is_new_user]
    assert result.value[:token].present?
    assert Identity.exists?(provider: "google", uid: "g-001")
  end

  test "logs in existing identity without creating duplicate user" do
    user = User.create!(email: "returning_social@example.com")
    user.identities.create!(provider: "google", uid: "g-002", email: user.email)
    raw_state, = OauthState.create_for!(provider: "google")
    fake = FakeProvider.new(profile: { uid: "g-002", email: user.email, email_verified: true, name: "Returning" })

    result = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "auth-code", state: raw_state)
    end

    assert result.success?
    assert_equal false, result.value[:is_new_user]
    assert_equal 1, User.where(email: user.email).count
  end

  test "auto-links existing user when provider email is verified" do
    user = User.create!(email: "magic_only@example.com")
    raw_state, = OauthState.create_for!(provider: "google")
    fake = FakeProvider.new(profile: { uid: "g-003", email: user.email, email_verified: true, name: "Magic" })

    result = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "auth-code", state: raw_state)
    end

    assert result.success?
    assert_equal false, result.value[:is_new_user]
    assert user.reload.identities.exists?(provider: "google", uid: "g-003")
    assert user.email_verified_at.present?
  end

  test "refuses auto-link when provider email is unverified for existing user" do
    user = User.create!(email: "unverified_match@example.com")
    raw_state, = OauthState.create_for!(provider: "google")
    fake = FakeProvider.new(profile: { uid: "g-004", email: user.email, email_verified: false, name: "Unverified" })

    result = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "auth-code", state: raw_state)
    end

    assert result.failure?
    assert_equal :unverified_provider_email, result.error
    assert_not user.identities.exists?(provider: "google")
  end

  test "rejects facebook login when email is missing" do
    raw_state, = OauthState.create_for!(provider: "facebook")
    fake = FakeProvider.new(
      error: Oauth::Providers::Base::ProviderError.new("Email required", code: :email_required)
    )

    result = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "facebook", code: "fb-code", state: raw_state)
    end

    assert result.failure?
    assert_equal :email_required, result.error
  end

  test "rejects expired, reused, or provider-mismatched state" do
    raw_state, state_record = OauthState.create_for!(provider: "google")
    state_record.update!(expires_at: 1.minute.ago)
    fake = FakeProvider.new(profile: { uid: "g-exp", email: "exp@example.com", email_verified: true })

    expired_res = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "code", state: raw_state)
    end
    assert expired_res.failure?
    assert_equal :invalid_token, expired_res.error

    google_state, = OauthState.create_for!(provider: "google")
    mismatch_res = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "facebook", code: "code", state: google_state)
    end
    assert mismatch_res.failure?
    assert_equal :invalid_token, mismatch_res.error

    ok_res = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "code", state: google_state)
    end
    assert ok_res.success?

    replay_res = with_fake_provider(fake) do
      Oauth::CompleteLoginService.call(provider: "google", code: "code", state: google_state)
    end
    assert replay_res.failure?
    assert_equal :invalid_token, replay_res.error
  end

  test "unlink identity blocks removing last login method and succeeds when another method exists" do
    user = User.create!(email: "unlink_user@example.com")
    user.identities.create!(provider: "google", uid: "g-unlink", email: user.email)

    blocked = Oauth::UnlinkIdentityService.call(email: user.email, provider: "google")
    assert blocked.failure?
    assert_equal :last_login_method, blocked.error
    assert user.identities.exists?(provider: "google")

    user.update!(password: "backup-password-123")
    allowed = Oauth::UnlinkIdentityService.call(email: user.email, provider: "google")
    assert allowed.success?
    assert_not user.identities.exists?(provider: "google")
  end
end
