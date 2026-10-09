require "test_helper"

class SessionsControllerTest < ActionDispatch::IntegrationTest
  test "should get login page" do
    get login_path
    assert_response :success
  end

  test "should redirect to dashboard when already logged in" do
    post login_path, params: { magic_link_form: { email: "user@example.com" } }
    token = SessionToken.last.token
    get magic_login_path(token)

    get login_path
    assert_redirected_to dashboard_path
  end

  test "should create magic link and redirect to check email" do
    assert_emails 1 do
      post login_path, params: { magic_link_form: { email: "user@example.com" } }
    end
    assert_redirected_to check_email_path(email: "user@example.com")

    # Verify SessionToken was created
    token_record = SessionToken.last
    assert_equal "user@example.com", token_record.email
    assert_not_nil token_record.token
    assert_not token_record.expired?
  end

  test "should render new when magic link submission fails" do
    post login_path, params: { magic_link_form: { email: "invalid-email" } }
    assert_response :unprocessable_entity
  end

  test "should enforce rate limit on magic link requests per email" do
    email = "spammer@example.com"
    5.times do
      SessionToken.create!(email: email)
    end

    assert_no_emails do
      post login_path, params: { magic_link_form: { email: email } }
    end
    assert_response :unprocessable_entity
    assert_includes response.body, I18n.t("errors.messages.magic_link_rate_limit_exceeded")
  end

  test "should authenticate magic link token and log in" do
    token_record = SessionToken.create!(email: "user@example.com")

    get magic_login_path(token_record.token)
    assert_redirected_to dashboard_path
    assert_equal "user@example.com", session[:current_user_email]

    token_record.reload
    assert token_record.used?
    assert_not_nil token_record.used_at
  end

  test "should redirect to return_to after magic login when present" do
    token_record = SessionToken.create!(email: "user@example.com")

    get letter_path(123)
    assert_redirected_to login_path
    assert_equal letter_path(123), session[:return_to]

    get magic_login_path(token_record.token)
    assert_redirected_to letter_path(123)
    assert_nil session[:return_to]
  end

  test "should not authenticate expired or invalid token" do
    # 1. Invalid token
    get magic_login_path("invalid-token")
    assert_redirected_to login_path
    assert_nil session[:current_user_email]

    # 2. Expired token
    token_record = SessionToken.new(email: "user@example.com")
    token_record.valid? # triggers token generation
    token_record.expires_at = 10.minutes.ago
    token_record.save!

    get magic_login_path(token_record.token)
    assert_redirected_to login_path
    assert_nil session[:current_user_email]
  end

  test "should log out" do
    # Log in
    token_record = SessionToken.create!(email: "user@example.com")
    get magic_login_path(token_record.token)
    assert_equal "user@example.com", session[:current_user_email]

    # Log out
    delete logout_path
    assert_redirected_to root_path
    assert_nil session[:current_user_email]
  end
end
