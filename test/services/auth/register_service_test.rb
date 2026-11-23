# frozen_string_literal: true

require "test_helper"

class Auth::RegisterServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  test "registers new user and issues session token" do
    result = Auth::RegisterService.call(
      email: "new_account@example.com",
      password: "super-secure-password",
      password_confirmation: "super-secure-password"
    )

    assert result.success?
    assert_equal "new_account@example.com", result.value[:email]
    assert_equal true, result.value[:is_new_user]
    assert result.value[:token].present?
    assert User.find_by(email: "new_account@example.com")&.has_password?
  end

  test "fails with field error when email already has a password" do
    User.create!(email: "taken@example.com", password: "existing-password-123")

    result = Auth::RegisterService.call(
      email: "taken@example.com",
      password: "another-password-123"
    )

    assert result.failure?
    assert_equal :invalid, result.error
    assert result.errors[:email].any?
  end

  test "dispatches magic link generically when email exists without password" do
    User.create!(email: "legacy_user@example.com")

    assert_enqueued_emails 1 do
      result = Auth::RegisterService.call(
        email: "legacy_user@example.com",
        password: "new-password-123"
      )

      assert result.success?
      assert_equal true, result.value[:requires_email_verification]
      assert_nil result.value[:token]
    end
  end

  test "fails when password is too short" do
    result = Auth::RegisterService.call(email: "shortpw@example.com", password: "short")

    assert result.failure?
    assert_equal :invalid, result.error
    assert result.errors[:password].any?
  end
end
