require "test_helper"

class AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @email = "traveler@timeecho.com"
    @letter = Letter.create!(
      email: @email,
      title: "Letter to future",
      content: "Deep emotional retrospection.",
      deliver_at: Date.current + 1.year
    )
  end

  def sign_in(email)
    token_record = SessionToken.create!(email: email)
    get magic_login_path(token_record.token)
  end

  test "should redirect show when not logged in" do
    get account_url
    assert_redirected_to login_url
  end

  test "should get account page when logged in" do
    sign_in(@email)

    get account_url
    assert_response :success
    assert_select "h1", text: "Ajustes de cuenta"
  end

  test "should update account and redirect with success notice" do
    sign_in(@email)

    patch account_url, params: {
      email: @email
    }

    assert_redirected_to account_url
    follow_redirect!
    assert_match "Ajustes guardados", response.body
  end

  test "should update account via turbo_stream" do
    sign_in(@email)

    patch account_url, as: :turbo_stream, params: {
      email: @email
    }

    assert_response :success
    assert_match "Ajustes actualizados correctamente", response.body
  end

  test "should destroy account and delete all associated letters and clear session" do
    sign_in(@email)

    assert_equal 1, Letter.where(email: @email).count

    assert_difference -> { Letter.where(email: @email).count } => -1, -> { AuditLog.for_action("letter.deleted").count } => 1 do
      delete account_url
    end

    assert_redirected_to root_url
    assert_nil session[:current_user_email]
  end

  test "should handle email update request in account update" do
    sign_in(@email)

    assert_enqueued_emails 1 do
      patch account_url, params: {
        email: "new_email@timeecho.com"
      }
    end

    assert_redirected_to account_url
  end

  test "should render unprocessable entity when update service fails" do
    sign_in(@email)

    patch account_url, params: {
      email: "invalid"
    }
    assert_response :unprocessable_entity
  end
end
