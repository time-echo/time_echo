require "test_helper"

class EmailConfirmationTest < ActionDispatch::IntegrationTest
  setup do
    @old_email = "original@timeecho.com"
    @new_email = "newaddress@timeecho.com"
  end

  def sign_in(email)
    token_record = SessionToken.create!(email: email)
    get magic_login_path(token_record.token)
  end

  test "creating a letter while logged out creates letter and sends stamped confirmation email" do
    assert_difference -> { Letter.count } => 1 do
      assert_enqueued_emails 1 do
        post letters_url, params: {
          letter_form: {
            email: "stranger@timeecho.com",
            title: "Anonymous Capsule",
            content: "I will be confirmed by this email verification flow when writing a time capsule letter.",
            deliver_at: Date.current + 1.year,
            happiness_level: "5",
            anxiety_level: "5",
            motivation_level: "5"
          }
        }
      end
    end

    assert_redirected_to success_letters_url
    assert_equal "stranger@timeecho.com", Letter.last.email
  end

  test "updating email in Settings does not change it immediately and dispatches mailer" do
    sign_in(@old_email)

    assert_enqueued_emails 1 do
      patch settings_url, params: {
        email: @new_email
      }
    end

    assert_redirected_to settings_url
    follow_redirect!
    assert_match "Hemos enviado un correo de confirmación", response.body
  end

  test "confirming email update via token completes the migration transaction" do
    sign_in(@old_email)

    Letter.create!(
      email: @old_email,
      title: "My Legacy",
      content: "Nostalgic letter.",
      deliver_at: Date.current + 2.years
    )

    token = Rails.application.message_verifier(:email_update).generate(
      { old_email: @old_email, new_email: @new_email },
      expires_in: 15.minutes
    )

    get confirm_email_update_settings_url(token: token)

    assert_redirected_to settings_url
    follow_redirect!
    assert_match "Dirección de correo electrónico confirmada y actualizada", response.body

    assert_equal 0, Letter.where(email: @old_email).count
    assert_equal 1, Letter.where(email: @new_email).count
    assert_equal @new_email, session[:current_user_email]
  end

  test "invalid token for email update displays error" do
    sign_in(@old_email)

    get confirm_email_update_settings_url(token: "invalid-token-123")

    assert_redirected_to settings_url
    follow_redirect!
    assert_match "El enlace de confirmación no es válido o ha caducado", response.body
  end
end
