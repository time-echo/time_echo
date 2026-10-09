require "test_helper"

class Letters::DeliverServiceTest < ActiveSupport::TestCase
  include ActionMailer::TestHelper

  def build_queued_letter(overrides = {})
    letter = Letter.new({
      title: "Deliver Service Test",
      email: "deliver@example.com",
      content: "Testing delivery",
      deliver_at: 1.day.ago,
      status: "queued"
    }.merge(overrides))
    letter.save!(validate: false)
    letter
  end

  test "delivers letter synchronously and marks it delivered" do
    letter = build_queued_letter

    assert_difference -> { AuditLog.for_action("letter.delivered").count } => 1 do
      assert_emails 1 do
        Letters::DeliverService.call(letter)
      end
    end

    letter.reload
    assert_equal "delivered", letter.status
    assert_not_nil letter.delivered_at
  end

  test "is idempotent — returns early if already delivered" do
    letter = build_queued_letter(status: "delivered", delivered_at: 5.minutes.ago)

    assert_emails 0 do
      Letters::DeliverService.call(letter)
    end

    letter.reload
    assert_equal "delivered", letter.status
  end

  test "delivers using the letter's stored language locale" do
    letter = build_queued_letter(language: "es")
    captured_locale = nil

    original = LetterMailer.method(:future_letter)
    LetterMailer.define_singleton_method(:future_letter) do |ltr|
      captured_locale = I18n.locale.to_s
      original.call(ltr)
    end

    I18n.with_locale(:en) { Letters::DeliverService.call(letter) }

    assert_equal "es", captured_locale
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "re-raises mailer errors without swallowing them" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise StandardError, "SMTP failure"
    end

    assert_raises(StandardError) { Letters::DeliverService.call(letter) }
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "does not mark letter failed on error — that is the job's responsibility" do
    letter = build_queued_letter
    original = LetterMailer.method(:future_letter)

    LetterMailer.define_singleton_method(:future_letter) do |*|
      raise StandardError, "SMTP failure"
    end

    assert_raises(StandardError) { Letters::DeliverService.call(letter) }

    letter.reload
    assert_not_equal "failed", letter.status,
      "DeliverService must not set failed — DeliverLetterJob owns that transition"
  ensure
    LetterMailer.define_singleton_method(:future_letter, original.to_proc)
  end

  test "does not deliver letter if letter is archived" do
    letter = build_queued_letter(status: "archived")

    assert_emails 0 do
      Letters::DeliverService.call(letter)
    end

    letter.reload
    assert_equal "archived", letter.status
  end
end
