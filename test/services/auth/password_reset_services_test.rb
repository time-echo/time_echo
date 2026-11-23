# frozen_string_literal: true

require "test_helper"

class Auth::PasswordResetServicesTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  setup do
    @user = User.create!(email: "reset_flow@example.com", password: "old-password-123")
  end

  test "request password reset returns identical success for known and unknown emails" do
    unknown_result = nil
    assert_no_enqueued_emails do
      unknown_result = Auth::RequestPasswordResetService.call(email: "unknown_person@example.com", locale: :en)
    end

    known_result = nil
    assert_enqueued_emails 1 do
      known_result = Auth::RequestPasswordResetService.call(email: @user.email, locale: :en)
    end

    assert unknown_result.success?
    assert known_result.success?
    assert_equal unknown_result.value[:message], known_result.value[:message]
    assert @user.reload.reset_token_digest.present?
  end

  test "reset password updates password, revokes all active sessions, and invalidates token" do
    active_session = SessionToken.create!(email: @user.email)
    raw_token = @user.generate_reset_token!

    result = Auth::ResetPasswordService.call(
      token: raw_token,
      password: "brand-new-password-456",
      password_confirmation: "brand-new-password-456"
    )

    assert result.success?
    assert @user.reload.authenticate("brand-new-password-456")
    assert_nil @user.reset_token_digest
    assert @user.email_verified_at.present?
    assert active_session.reload.used?, "All active sessions must be revoked on password reset"

    second_attempt = Auth::ResetPasswordService.call(
      token: raw_token,
      password: "another-password-789"
    )
    assert second_attempt.failure?
    assert_equal :invalid_token, second_attempt.error
  end

  test "reset password rejects expired tokens" do
    raw_token = @user.generate_reset_token!
    @user.update!(reset_sent_at: 2.hours.ago)

    result = Auth::ResetPasswordService.call(token: raw_token, password: "brand-new-password-456")

    assert result.failure?
    assert_equal :invalid_token, result.error
  end
end
