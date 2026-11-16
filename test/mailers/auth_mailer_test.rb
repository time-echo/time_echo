require "test_helper"

class AuthMailerTest < ActionMailer::TestCase
  test "magic_link" do
    mail = AuthMailer.magic_link("user@example.com", "token123")
    assert_equal [ "user@example.com" ], mail.to
    assert_equal [ "no-reply@timeecho.me" ], mail.from
    assert_equal "TimeEcho <no-reply@timeecho.me>", mail[:from].decoded
    assert_equal I18n.t("mailers.magic_link.subject"), mail.subject
  end

  test "magic_link renders html and text parts with frontend login url using APP_HOST" do
    original_host = ENV["APP_HOST"]
    begin
      ENV["APP_HOST"] = "localhost:3001"
      mail = AuthMailer.magic_link("user@example.com", "token123")
      html_body = mail.html_part.body.decoded
      text_body = mail.text_part.body.decoded

      assert_includes html_body, "TimeEcho"
      assert_includes html_body, "btn-carmine"
      assert_includes html_body, "http://localhost:3001/login/token123"
      assert_includes text_body, "http://localhost:3001/login/token123"

      ENV["APP_HOST"] = "https://app.timeecho.me/"
      mail_with_protocol = AuthMailer.magic_link("user@example.com", "token456")
      assert_includes mail_with_protocol.text_part.body.decoded, "https://app.timeecho.me/login/token456"
    ensure
      ENV["APP_HOST"] = original_host
    end
  end

  test "magic_link renders in Spanish when locale: :es is provided" do
    mail = AuthMailer.magic_link("user@example.com", "token123", :es)
    assert_equal "Tu enlace de acceso a TimeEcho", mail.subject
    assert_includes mail.html_part.body.decoded, "Inicia sesión en TimeEcho"
    assert_includes mail.html_part.body.decoded, "Hola,"
    assert_includes mail.html_part.body.decoded, "Iniciar sesión"
    assert_includes mail.text_part.body.decoded, "Inicia sesión en TimeEcho"
    assert_includes mail.text_part.body.decoded, "Este enlace vence en 15 minutos."
    assert_includes mail.html_part.body.decoded, 'lang="es"'
  end

  test "magic_link renders in English when locale: :en is provided" do
    mail = AuthMailer.magic_link("user@example.com", "token123", :en)
    assert_equal "Your TimeEcho sign-in link", mail.subject
    assert_includes mail.html_part.body.decoded, "Sign in to TimeEcho"
    assert_includes mail.html_part.body.decoded, "Hello,"
    assert_includes mail.html_part.body.decoded, "Sign in"
    assert_includes mail.text_part.body.decoded, "Sign in to TimeEcho"
    assert_includes mail.text_part.body.decoded, "This link expires in 15 minutes."
    assert_includes mail.html_part.body.decoded, 'lang="en"'
  end
end
