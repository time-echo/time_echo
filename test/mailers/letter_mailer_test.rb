require "test_helper"

class LetterMailerTest < ActionMailer::TestCase
  test "future_letter uses letter locale" do
    letter = Letter.new(
      title: "Test",
      email: "user@example.com",
      content: "Hello",
      deliver_at: 1.day.ago,
      status: "delivered",
      language: "es"
    )
    letter.save!(validate: false)

    I18n.with_locale(:en) do
      mail = LetterMailer.future_letter(letter)
      assert_equal [ "user@example.com" ], mail.to
      spanish_subject = I18n.with_locale(:es) { I18n.t("mailers.future_letter.subject", date: I18n.l(letter.created_at.to_date, format: :long)) }
      assert_equal spanish_subject, mail.subject
    end
  end

  test "future_letter uses dynamic default from address" do
    letter = Letter.new(
      title: "Test",
      email: "user@example.com",
      content: "Hello",
      deliver_at: 1.day.ago,
      status: "delivered",
      language: "en"
    )
    letter.save!(validate: false)

    mail = LetterMailer.future_letter(letter)
    assert_equal [ "no-reply@timeecho.me" ], mail.from
    assert_equal "TimeEcho <no-reply@timeecho.me>", mail[:from].decoded
  end

  test "future_letter dynamically adapts to MAILER_SENDER environment variable" do
    letter = Letter.new(
      title: "Test",
      email: "user@example.com",
      content: "Hello",
      deliver_at: 1.day.ago,
      status: "delivered",
      language: "en"
    )
    letter.save!(validate: false)

    original_sender = ENV["MAILER_SENDER"]
    begin
      ENV["MAILER_SENDER"] = "letters@timeecho.me"
      mail = LetterMailer.future_letter(letter)
      assert_equal [ "letters@timeecho.me" ], mail.from
      assert_equal "TimeEcho <letters@timeecho.me>", mail[:from].decoded

      ENV["MAILER_SENDER"] = "TimeEcho Letters <letters@timeecho.me>"
      mail = LetterMailer.future_letter(letter)
      assert_equal [ "letters@timeecho.me" ], mail.from
      assert_equal "TimeEcho Letters <letters@timeecho.me>", mail[:from].decoded
    ensure
      ENV["MAILER_SENDER"] = original_sender
    end
  end

  test "future_letter renders postal layout, truncated excerpt, predictions prompt, and carmine button" do
    long_content = "This is a long archival letter to my future self written during a rainy afternoon. " \
                   "I wonder if you still remember how this season felt and whether all those dreams " \
                   "and career aspirations finally materialized in the timeline."
    letter = Letter.new(
      title: "Letter to Future Me",
      email: "user@example.com",
      content: long_content,
      deliver_at: 1.day.ago,
      status: "delivered",
      language: "en"
    )
    letter.save!(validate: false)

    mail = LetterMailer.future_letter(letter)
    html_body = mail.html_part.body.decoded
    text_body = mail.text_part.body.decoded

    assert_includes html_body, "TimeEcho"
    assert_includes html_body, "btn-carmine"
    assert_includes html_body, "Open My Letter"
    assert_includes text_body, "Open My Letter"
    assert_includes html_body, "View your full letter and compare your past predictions."
    assert_includes text_body, "View your full letter and compare your past predictions."
    assert_includes html_body, "This is a long archival letter"
    assert_includes html_body, "…"
    refute_includes html_body, "materialized in the timeline."
    assert_includes text_body, "This is a long archival letter"
    assert_includes text_body, "…"
    refute_includes text_body, "materialized in the timeline."
  end

  test "stamped_confirmation renders title and button redirecting to TimeEcho without content or archived wording" do
    letter = Letter.new(
      title: "Letter Stamped Test",
      email: "stamped@example.com",
      content: "This is my private secret letter copy",
      deliver_at: 1.year.from_now,
      status: "pending",
      language: "es"
    )
    letter.save!(validate: false)

    mail = LetterMailer.stamped_confirmation(letter)
    assert_equal [ "stamped@example.com" ], mail.to
    assert_equal I18n.t("mailers.stamped_confirmation.subject", title: letter.title), mail.subject
    assert_equal letter.id.to_s, mail.header["X-Letter-ID"].value

    html_body = mail.html_part.body.decoded
    text_body = mail.text_part.body.decoded

    assert_includes html_body, "Letter Stamped Test"
    assert_includes text_body, "Letter Stamped Test"

    refute_includes html_body, "This is my private secret letter copy"
    refute_includes text_body, "This is my private secret letter copy"

    refute_match(/archived|archivad[oa]/i, html_body)
    refute_match(/archived|archivad[oa]/i, text_body)

    refute_match(/class="[^"]*btn-carmine[^"]*"/, html_body)

    assert_match(%r{<a [^>]*href="[^"]*"[^>]*>.*#{Regexp.escape(I18n.t("brand"))}.*#{Regexp.escape(I18n.t("mailers.stamped_confirmation.footer_subtitle"))}.*</a>}m, html_body)
    assert_includes text_body, "http://localhost:3001/"
  end
end
