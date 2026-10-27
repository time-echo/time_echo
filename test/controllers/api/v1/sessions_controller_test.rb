# frozen_string_literal: true

require "test_helper"

class Api::V1::SessionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_email = "api_auth_user@example.com"
  end

  test "POST /api/v1/sessions dispatches magic link and returns 201 created" do
    assert_emails 1 do
      post "/api/v1/sessions", params: { email: @user_email }, as: :json
    end

    json = assert_resource_response(expected_status: :created)
    assert_equal @user_email, json["data"]["email"]
    assert json["data"]["message"].present?

    token_record = SessionToken.last
    assert_equal @user_email, token_record.email
    assert_not token_record.expired?
    assert_not token_record.used?
  end

  test "POST /api/v1/sessions accepts nested session payload" do
    assert_emails 1 do
      post "/api/v1/sessions", params: { session: { email: @user_email } }, as: :json
    end

    assert_resource_response(expected_status: :created)
  end

  test "POST /api/v1/sessions returns 400 bad_request when email parameter is missing" do
    post "/api/v1/sessions", params: {}, as: :json
    assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
  end

  test "POST /api/v1/sessions returns 422 validation_failed when email is invalid" do
    post "/api/v1/sessions", params: { email: "not-an-email" }, as: :json
    json = assert_error_response(expected_status: :unprocessable_entity, expected_code: "validation_failed")
    assert json["error"]["details"].present?
  end

  test "POST /api/v1/sessions returns 429 rate_limited when rate limit is exceeded" do
    5.times do
      SessionToken.create!(email: @user_email)
    end

    assert_no_emails do
      post "/api/v1/sessions", params: { email: @user_email }, as: :json
    end

    assert_error_response(expected_status: :too_many_requests, expected_code: "rate_limited")
  end

  test "GET /api/v1/sessions/:token authenticates valid token and sets session" do
    token_record = SessionToken.create!(email: @user_email)

    get "/api/v1/sessions/#{token_record.token}", as: :json
    json = assert_resource_response(expected_status: :ok)

    assert_equal @user_email, json["data"]["email"]
    assert json["data"]["token"].present?
    assert_equal @user_email, session[:current_user_email]

    token_record.reload
    assert token_record.used?

    # Verify returned token is active and usable for bearer/header auth
    returned_token = json["data"]["token"]
    assert SessionToken.active.exists?(token: returned_token)
  end

  test "GET /api/v1/sessions/:token returns 401 unauthorized when token is invalid" do
    get "/api/v1/sessions/nonexistent_token", as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "GET /api/v1/sessions/:token returns 401 unauthorized when token is expired" do
    token_record = SessionToken.create!(email: @user_email, expires_at: 10.minutes.ago)

    get "/api/v1/sessions/#{token_record.token}", as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "GET /api/v1/sessions/me returns 401 unauthorized when not logged in" do
    get "/api/v1/sessions/me", as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "GET /api/v1/sessions/me returns current user profile when authenticated via session" do
    token_record = SessionToken.create!(email: @user_email)
    get "/api/v1/sessions/#{token_record.token}", as: :json

    get "/api/v1/sessions/me", as: :json
    json = assert_resource_response(expected_status: :ok)

    assert_equal true, json["data"]["authenticated"]
    assert_equal @user_email, json["data"]["email"]
    assert json["data"]["locale"].present?
  end

  test "GET /api/v1/sessions/me returns current user profile when authenticated via X-Session-Token" do
    token_record = SessionToken.create!(email: @user_email)

    get "/api/v1/sessions/me", headers: { "X-Session-Token" => token_record.token }, as: :json
    json = assert_resource_response(expected_status: :ok)

    assert_equal true, json["data"]["authenticated"]
    assert_equal @user_email, json["data"]["email"]
  end

  test "GET /api/v1/sessions/me returns current user profile when authenticated via Bearer token" do
    token_record = SessionToken.create!(email: @user_email)

    get "/api/v1/sessions/me", headers: { "Authorization" => "Bearer #{token_record.token}" }, as: :json
    json = assert_resource_response(expected_status: :ok)

    assert_equal true, json["data"]["authenticated"]
    assert_equal @user_email, json["data"]["email"]
  end

  test "DELETE /api/v1/sessions returns 401 unauthorized when not authenticated" do
    delete "/api/v1/sessions", as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "DELETE /api/v1/sessions logs out and clears cookie session" do
    token_record = SessionToken.create!(email: @user_email)
    get "/api/v1/sessions/#{token_record.token}", as: :json
    assert_equal @user_email, session[:current_user_email]

    delete "/api/v1/sessions", as: :json
    assert_response :no_content
    assert_nil session[:current_user_email]
  end

  test "DELETE /api/v1/sessions deactivates active token when using header auth" do
    token_record = SessionToken.create!(email: @user_email)

    delete "/api/v1/sessions", headers: { "X-Session-Token" => token_record.token }, as: :json
    assert_response :no_content

    token_record.reload
    assert token_record.used?
  end
end
