require "test_helper"

class Settings::EmailUpdateServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper
  test "request email update succeeds with valid new email" do
    assert_enqueued_emails 1 do
      result = Settings::RequestEmailUpdateService.call("new@example.com", "old@example.com")
      assert result.success?
    end
  end

  test "request email update fails with invalid email" do
    result = Settings::RequestEmailUpdateService.call("invalid-email", "old@example.com")
    assert_not result.success?
    assert_includes result.error, "introduce un correo"
  end

  test "request email update fails when new email is same as old" do
    result = Settings::RequestEmailUpdateService.call("same@example.com", "same@example.com")
    assert_not result.success?
    assert_includes result.error, "no puede ser igual"
  end

  test "confirm email update migrates letters" do
    Letter.create!(
      email: "old@example.com",
      title: "Test Letter",
      content: "Archival content",
      deliver_at: 1.year.from_now
    )

    token = Rails.application.message_verifier(:email_update).generate(
      { old_email: "old@example.com", new_email: "new@example.com" },
      expires_in: 15.minutes
    )

    result = Settings::ConfirmEmailUpdateService.call(token)
    assert result.success?
    assert_equal "new@example.com", result.new_email

    assert_equal 0, Letter.where(email: "old@example.com").count
    assert_equal 1, Letter.where(email: "new@example.com").count
  end

  test "confirm email update fails with blank or invalid token" do
    assert_not Settings::ConfirmEmailUpdateService.call(nil).success?
    assert_not Settings::ConfirmEmailUpdateService.call("").success?
    assert_not Settings::ConfirmEmailUpdateService.call("invalid-token").success?

    string_token = Rails.application.message_verifier(:email_update).generate("not-a-hash")
    assert_not Settings::ConfirmEmailUpdateService.call(string_token).success?

    empty_hash_token = Rails.application.message_verifier(:email_update).generate({ old_email: "" })
    assert_not Settings::ConfirmEmailUpdateService.call(empty_hash_token).success?
  end
end
