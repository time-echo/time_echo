# frozen_string_literal: true

require "test_helper"

class Settings::UpdatePasswordServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "settings_pw@example.com", password: "current-password-123")
  end

  test "rejects wrong current password" do
    result = Settings::UpdatePasswordService.call(
      email: @user.email,
      current_password: "wrong-password-123",
      password: "new-password-456"
    )

    assert result.failure?
    assert_equal :invalid_current_password, result.error
    assert @user.reload.authenticate("current-password-123")
  end

  test "updates password and revokes other sessions while keeping current token" do
    current_session = SessionToken.create!(email: @user.email)
    other_session = SessionToken.create!(email: @user.email)

    result = Settings::UpdatePasswordService.call(
      email: @user.email,
      current_password: "current-password-123",
      password: "updated-password-456",
      password_confirmation: "updated-password-456",
      current_token: current_session.token
    )

    assert result.success?
    assert @user.reload.authenticate("updated-password-456")
    assert_not current_session.reload.used?, "Current session should stay active"
    assert other_session.reload.used?, "Other sessions should be revoked"
  end

  test "allows legacy passwordless user to set password for the first time" do
    legacy = User.create!(email: "legacy_settings@example.com")

    result = Settings::UpdatePasswordService.call(
      email: legacy.email,
      password: "first-time-password-123",
      password_confirmation: "first-time-password-123"
    )

    assert result.success?
    assert legacy.reload.authenticate("first-time-password-123")
  end
end
