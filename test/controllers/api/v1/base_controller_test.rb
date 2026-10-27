# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class DummyController < BaseController
      before_action :authenticate_user!, only: [ :protected_action ]

      def public_action
        render json: { user: current_user_email, locale: I18n.locale }
      end

      def protected_action
        render json: { status: "authenticated", email: current_user_email }
      end

      def error_action
        raise ActiveRecord::RecordNotFound, "Resource not found"
      end

      def invalid_action
        letter = Letter.new
        letter.validate
        raise ActiveRecord::RecordInvalid, letter
      end

      def conflict_action
        raise ActiveRecord::RecordNotUnique, "Duplicate record"
      end

      def forbidden_action
        raise Api::ForbiddenError, "Access forbidden"
      end

      def server_error_action
        raise "Unexpected standard error"
      end

      def bad_request_action
        params.require(:required_param)
        render json: { ok: true }
      end
    end
  end
end

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  test "returns 401 unauthorized when unauthenticated user accesses protected endpoint" do
    get "/api/v1/dummy/protected"

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "authenticates user via session cookie" do
    token_record = SessionToken.create!(email: "session_user@example.com")
    get magic_login_path(token_record.token)

    get "/api/v1/dummy/protected"

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "session_user@example.com", json["email"]
  end

  test "authenticates user via X-Session-Token header" do
    token_record = SessionToken.create!(email: "header_user@example.com")

    get "/api/v1/dummy/protected", headers: { "X-Session-Token" => token_record.token }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "header_user@example.com", json["email"]
  end

  test "authenticates user via Authorization Bearer token" do
    token_record = SessionToken.create!(email: "bearer_user@example.com")

    get "/api/v1/dummy/protected", headers: { "Authorization" => "Bearer #{token_record.token}" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "bearer_user@example.com", json["email"]
  end

  test "rejects expired or used session token" do
    token_record = SessionToken.create!(email: "expired@example.com", expires_at: 1.minute.ago)

    get "/api/v1/dummy/protected", headers: { "X-Session-Token" => token_record.token }

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "renders 404 json when ActiveRecord::RecordNotFound is raised" do
    get "/api/v1/dummy/error"

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "renders 422 json when ActiveRecord::RecordInvalid is raised" do
    get "/api/v1/dummy/invalid"

    json = assert_error_response(expected_status: :unprocessable_entity, expected_code: "validation_failed")
    assert json["error"]["details"].present?
  end

  test "renders 400 json when ActionController::ParameterMissing is raised" do
    post "/api/v1/dummy/bad_request", params: {}

    assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
  end

  test "detects locale from X-Locale header" do
    get "/api/v1/dummy/public", headers: { "X-Locale" => "es" }

    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "es", json["locale"]
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
end
