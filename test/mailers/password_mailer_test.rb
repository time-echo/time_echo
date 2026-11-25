# frozen_string_literal: true

require "test_helper"

class PasswordMailerTest < ActionMailer::TestCase
  test "reset email renders in English with reset link" do
    mail = PasswordMailer.reset("reader@example.com", "reset-token-abc", :en)

    assert_equal [ "reader@example.com" ], mail.to
    assert_equal "Reset your TimeEcho password", mail.subject
    assert_includes mail.html_part.body.decoded, "/reset-password/reset-token-abc"
    assert_includes mail.text_part.body.decoded, "/reset-password/reset-token-abc"
  end

  test "reset email renders in Spanish with reset link" do
    mail = PasswordMailer.reset("lector@example.com", "reset-token-xyz", :es)

    assert_equal [ "lector@example.com" ], mail.to
    assert_equal "Restablece tu contraseña de TimeEcho", mail.subject
    assert_includes mail.html_part.body.decoded, "/reset-password/reset-token-xyz"
    assert_includes mail.text_part.body.decoded, "/reset-password/reset-token-xyz"
  end
end
