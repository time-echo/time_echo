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

      def bad_request_action
        params.require(:required_param)
        render json: { ok: true }
      end
    end
  end
end

class Api::V1::BaseControllerTest < ActionDispatch::IntegrationTest
  setup do
    Rails.application.routes.draw do
      namespace :api, defaults: { format: :json } do
        namespace :v1 do
          get "dummy/public", to: "dummy#public_action"
          get "dummy/protected", to: "dummy#protected_action"
          get "dummy/error", to: "dummy#error_action"
          post "dummy/bad_request", to: "dummy#bad_request_action"
          get "ping", to: proc { [ 200, { "Content-Type" => "application/json" }, [ { status: "ok" }.to_json ] ] }
        end
      end
    end
  end

  teardown do
    Rails.application.reload_routes!
  end

  test "returns 401 unauthorized when unauthenticated user accesses protected endpoint" do
    get "/api/v1/dummy/protected"

    assert_response :unauthorized
    json = JSON.parse(response.body)
    assert_equal "unauthorized", json["error"]
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

    assert_response :unauthorized
  end

  test "renders 404 json when ActiveRecord::RecordNotFound is raised" do
    get "/api/v1/dummy/error"

    assert_response :not_found
    json = JSON.parse(response.body)
    assert_equal "not_found", json["error"]
  end

  test "renders 400 json when ActionController::ParameterMissing is raised" do
    post "/api/v1/dummy/bad_request", params: {}

    assert_response :bad_request
    json = JSON.parse(response.body)
    assert_equal "bad_request", json["error"]
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
