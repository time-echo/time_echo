# frozen_string_literal: true

require "test_helper"

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  test "returns 401 unauthorized when unauthenticated user accesses protected endpoint" do
    get "/api/v1/sessions/me"

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "authenticates user via session cookie" do
    token_record = SessionToken.create!(email: "session_user@example.com")
    get "/api/v1/sessions/#{token_record.token}", as: :json
    assert_response :ok

    get "/api/v1/sessions/me"

    json = assert_resource_response(expected_status: :ok)
    assert_equal "session_user@example.com", json["data"]["email"]
  end

  test "authenticates user via X-Session-Token header" do
    token_record = SessionToken.create!(email: "header_user@example.com")

    get "/api/v1/sessions/me", headers: { "X-Session-Token" => token_record.token }

    json = assert_resource_response(expected_status: :ok)
    assert_equal "header_user@example.com", json["data"]["email"]
  end

  test "authenticates user via Authorization Bearer token" do
    token_record = SessionToken.create!(email: "bearer_user@example.com")

    get "/api/v1/sessions/me", headers: { "Authorization" => "Bearer #{token_record.token}" }

    json = assert_resource_response(expected_status: :ok)
    assert_equal "bearer_user@example.com", json["data"]["email"]
  end

  test "rejects expired or used session token" do
    token_record = SessionToken.create!(email: "expired@example.com", expires_at: 1.minute.ago)

    get "/api/v1/sessions/me", headers: { "X-Session-Token" => token_record.token }

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "renders 404 json when resource is not found" do
    token_record = SessionToken.create!(email: "notfound_user@example.com")

    get "/api/v1/letters/999999", headers: { "Authorization" => "Bearer #{token_record.token}" }

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "renders 422 json when validation fails" do
    post "/api/v1/sessions", params: { email: "invalid-email" }, as: :json

    json = assert_error_response(expected_status: :unprocessable_content, expected_code: "validation_failed")
    assert json["error"]["details"].present?
  end

  test "renders 400 json when ActionController::ParameterMissing is raised" do
    post "/api/v1/sessions", params: {}

    assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
  end

  test "detects locale from X-Locale header" do
    get "/api/v1/sessions/me", headers: { "X-Locale" => "en" }

    json = assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
    assert_equal I18n.t("flash.login_required", locale: :en), json["error"]["message"]
  end

  test "detects locale from HTTP_ACCEPT_LANGUAGE header when X-Locale is absent" do
    get "/api/v1/sessions/me", headers: { "Accept-Language" => "en-US,en;q=0.9" }

    json = assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
    assert_equal I18n.t("flash.login_required", locale: :en), json["error"]["message"]
  end

  test "allows CORS preflight requests from localhost:3000 with credentials" do
    options "/api/v1/ping", headers: {
      "Origin" => "http://localhost:3000",
      "Access-Control-Request-Method" => "GET"
    }

    assert_response :success
    assert_equal "http://localhost:3000", response.headers["Access-Control-Allow-Origin"]
    assert_equal "true", response.headers["Access-Control-Allow-Credentials"]
  end

  test "GET /api/v1/ping returns ok status and timestamp" do
    get "/api/v1/ping", as: :json

    json = assert_resource_response(expected_status: :ok)
    assert_equal "ok", json["data"]["status"]
    assert json["data"]["timestamp"].present?
  end
end
