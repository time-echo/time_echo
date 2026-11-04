# frozen_string_literal: true

require "test_helper"

class SessionTokenTest < ActiveSupport::TestCase
  test "generates token and expiration on creation" do
    token_record = SessionToken.create!(email: "user@example.com")

    assert_predicate token_record.token, :present?
    assert_predicate token_record.expires_at, :present?
    assert_not token_record.expired?
    assert_not token_record.used?
  end

  test "normalizes email by stripping and downcasing" do
    token_record = SessionToken.create!(email: "  USER@EXAMPLE.COM  ")

    assert_equal "user@example.com", token_record.email
  end

  test "validates email format" do
    invalid = SessionToken.new(email: "not-an-email")

    assert_not invalid.valid?
    assert_includes invalid.errors[:email], I18n.t("errors.messages.invalid")
  end

  test "active scope only includes unexpired and unused tokens" do
    active_token = SessionToken.create!(email: "user@example.com")
    used_token = SessionToken.create!(email: "user@example.com", used_at: Time.current)
    expired_token = SessionToken.create!(email: "user@example.com", expires_at: 1.hour.ago)

    active_tokens = SessionToken.active

    assert_includes active_tokens, active_token
    assert_not_includes active_tokens, used_token
    assert_not_includes active_tokens, expired_token
  end

  test "revoke_active_for marks all active tokens for email as used" do
    email = "user@example.com"
    token1 = SessionToken.create!(email: email)
    token2 = SessionToken.create!(email: email)
    other_token = SessionToken.create!(email: "other@example.com")

    SessionToken.revoke_active_for(email)

    assert token1.reload.used?
    assert token2.reload.used?
    assert_not other_token.reload.used?
  end

  test "revoke_active_for safely handles blank email" do
    assert_equal 0, SessionToken.revoke_active_for("")
    assert_equal 0, SessionToken.revoke_active_for(nil)
  end

  test "use! and revoke! update used_at" do
    token_record = SessionToken.create!(email: "user@example.com")
    assert_not token_record.used?

    token_record.revoke!
    assert token_record.used?
    assert_predicate token_record.used_at, :present?
  end
end
