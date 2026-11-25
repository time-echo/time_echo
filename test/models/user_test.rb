# frozen_string_literal: true

require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "normalizes email on assignment" do
    user = User.new(email: "  Alice@Example.COM  ")
    assert_equal "alice@example.com", user.email
  end

  test "requires valid unique email" do
    User.create!(email: "unique@example.com")

    duplicate = User.new(email: "UNIQUE@example.com")
    assert_not duplicate.valid?
    assert duplicate.errors[:email].any?

    invalid = User.new(email: "not-an-email")
    assert_not invalid.valid?
    assert invalid.errors[:email].any?
  end

  test "validates password length when password is provided" do
    short = User.new(email: "short@example.com", password: "short")
    assert_not short.valid?
    assert short.errors[:password].any?

    valid = User.new(email: "valid@example.com", password: "a-very-secure-password")
    assert valid.valid?
  end

  test "allows passwordless user creation for legacy and oauth flows" do
    user = User.create!(email: "legacy@example.com")
    assert_not user.has_password?
    assert_equal 0, user.login_methods_count
  end

  test "generates, verifies, and expires reset tokens" do
    user = User.create!(email: "reset@example.com", password: "initial-password-123")
    raw_token = user.generate_reset_token!

    assert_not_equal raw_token, user.reset_token_digest
    assert user.reset_token_valid?(raw_token)
    assert_not user.reset_token_valid?("wrong-token")
    assert_equal user, User.find_by_reset_token(raw_token)

    user.update!(reset_sent_at: 2.hours.ago)
    assert_not user.reset_token_valid?(raw_token)
    assert_nil User.find_by_reset_token(raw_token)
  end
end
