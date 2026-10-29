# frozen_string_literal: true

require "test_helper"

class Api::V1::AccountsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @email = "account_user@example.com"
    @token_record = SessionToken.create!(email: @email)
    @auth_headers = { "Authorization" => "Bearer #{@token_record.token}" }
    @letter = Letter.create!(
      email: @email,
      title: "Letter to future",
      content: "Deep emotional retrospection.",
      scheduled_at: 1.year.from_now
    )
  end

  test "PATCH /api/v1/account returns 401 when unauthorized" do
    patch "/api/v1/account", params: { email: "new@example.com" }, as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "PATCH /api/v1/account returns 400 when email parameter is missing" do
    patch "/api/v1/account", params: {}, headers: @auth_headers, as: :json
    assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
  end

  test "PATCH /api/v1/account returns 422 when email is unchanged" do
    patch "/api/v1/account", params: { email: @email }, headers: @auth_headers, as: :json
    assert_error_response(expected_status: :unprocessable_content, expected_code: "same_email")
  end

  test "PATCH /api/v1/account returns 422 when email is invalid" do
    patch "/api/v1/account", params: { email: "invalid-email" }, headers: @auth_headers, as: :json
    assert_error_response(expected_status: :unprocessable_content, expected_code: "validation_failed")
  end

  test "PATCH /api/v1/account dispatches confirmation email when new email is provided" do
    new_email = "brand_new@example.com"
    assert_enqueued_emails 1 do
      patch "/api/v1/account", params: { email: new_email }, headers: @auth_headers, as: :json
    end

    json = assert_resource_response(expected_status: :ok)
    assert_equal new_email, json["data"]["email"]
  end

  test "PATCH /api/v1/account accepts nested account[email] parameter" do
    new_email = "nested_new@example.com"
    assert_enqueued_emails 1 do
      patch "/api/v1/account", params: { account: { email: new_email } }, headers: @auth_headers, as: :json
    end

    json = assert_resource_response(expected_status: :ok)
    assert_equal new_email, json["data"]["email"]
  end

  test "GET /api/v1/account/confirm_email confirms email migration and updates session" do
    new_email = "confirmed@example.com"
    token = Rails.application.message_verifier(:email_update).generate(
      { old_email: @email, new_email: new_email },
      expires_in: 15.minutes
    )

    get "/api/v1/account/confirm_email", params: { token: token }

    json = assert_resource_response(expected_status: :ok)
    assert_equal new_email, json["data"]["email"]
    assert_equal 0, Letter.where(email: @email).count
    assert_equal 1, Letter.where(email: new_email).count
  end

  test "POST /api/v1/account/confirm_email confirms email migration" do
    new_email = "confirmed_post@example.com"
    token = Rails.application.message_verifier(:email_update).generate(
      { old_email: @email, new_email: new_email },
      expires_in: 15.minutes
    )

    post "/api/v1/account/confirm_email", params: { token: token }, as: :json

    json = assert_resource_response(expected_status: :ok)
    assert_equal new_email, json["data"]["email"]
    assert_equal 1, Letter.where(email: new_email).count
  end

  test "GET /api/v1/account/confirm_email returns 401 when token is invalid" do
    get "/api/v1/account/confirm_email", params: { token: "invalid-token" }
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "DELETE /api/v1/account returns 401 when unauthorized" do
    delete "/api/v1/account", as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "DELETE /api/v1/account wipes letters, revokes session, and returns 204" do
    assert_difference -> { Letter.where(email: @email).count } => -1 do
      delete "/api/v1/account", headers: @auth_headers, as: :json
    end

    assert_response :no_content
    assert_not SessionToken.active.exists?(email: @email)
  end
end
