# frozen_string_literal: true

require "test_helper"

class Auth::PasswordLoginServiceTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "login_user@example.com", password: "correct-password-123")
  end

  test "authenticates user with valid email and password" do
    result = Auth::PasswordLoginService.call(email: "LOGIN_USER@example.com", password: "correct-password-123")

    assert result.success?
    assert_equal "login_user@example.com", result.value[:email]
    assert result.value[:token].present?
    assert_equal false, result.value[:is_new_user]
    assert SessionToken.active.exists?(token: result.value[:token])
  end

  test "returns generic invalid_credentials for wrong password" do
    result = Auth::PasswordLoginService.call(email: @user.email, password: "wrong-password-123")

    assert result.failure?
    assert_equal :invalid_credentials, result.error
  end

  test "returns generic invalid_credentials for unknown email" do
    result = Auth::PasswordLoginService.call(email: "nobody@example.com", password: "any-password-123")

    assert result.failure?
    assert_equal :invalid_credentials, result.error
  end

  test "returns generic invalid_credentials for passwordless legacy user" do
    legacy = User.create!(email: "legacy_only@example.com")
    result = Auth::PasswordLoginService.call(email: legacy.email, password: "some-password-123")

    assert result.failure?
    assert_equal :invalid_credentials, result.error
  end
end
