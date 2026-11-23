# frozen_string_literal: true

require "test_helper"

class IdentityTest < ActiveSupport::TestCase
  setup do
    @user = User.create!(email: "identity_owner@example.com")
  end

  test "validates provider inclusion and uniqueness" do
    identity = @user.identities.create!(provider: "google", uid: "google-123", email: "identity_owner@example.com")
    assert identity.persisted?

    invalid_provider = @user.identities.build(provider: "twitter", uid: "tw-1")
    assert_not invalid_provider.valid?

    other_user = User.create!(email: "other_owner@example.com")
    duplicate_uid = other_user.identities.build(provider: "google", uid: "google-123")
    assert_not duplicate_uid.valid?

    duplicate_provider_for_user = @user.identities.build(provider: "google", uid: "google-456")
    assert_not duplicate_provider_for_user.valid?
  end
end
