# frozen_string_literal: true

require "test_helper"

class Api::V1::ErrorHandlingTest < ActionDispatch::IntegrationTest
  def with_health_service_raising(exception)
    original_call = Health::CheckService.method(:call)
    Health::CheckService.define_singleton_method(:call) { raise exception }
    yield
  ensure
    Health::CheckService.define_singleton_method(:call, original_call.to_proc)
  end

  test "400 bad_request on ActionController::ParameterMissing" do
    post "/api/v1/sessions", params: {}

    json = assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
    assert_match(/email/i, json["error"]["message"])
  end

  test "400 bad_request on ActionDispatch::Http::Parameters::ParseError" do
    with_health_service_raising(ActionDispatch::Http::Parameters::ParseError.new("Malformed JSON")) do
      get "/api/v1/health"

      json = assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
      assert_equal "Invalid or malformed request parameters", json["error"]["message"]
    end
  end

  test "401 unauthorized when session token is missing or expired" do
    get "/api/v1/sessions/me"

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "403 forbidden on Api::ForbiddenError" do
    with_health_service_raising(Api::ForbiddenError.new("Access forbidden")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :forbidden, expected_code: "forbidden")
    end
  end

  test "404 not_found on ActiveRecord::RecordNotFound" do
    with_health_service_raising(ActiveRecord::RecordNotFound.new("Resource not found")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :not_found, expected_code: "not_found")
    end
  end

  test "404 not_found on catch-all route for unknown API path" do
    get "/api/v1/unknown_resource"

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "406 not_acceptable on ActionController::UnknownFormat" do
    with_health_service_raising(ActionController::UnknownFormat.new("ActionController::UnknownFormat")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :not_acceptable, expected_code: "not_acceptable")
    end
  end

  test "409 conflict on ActiveRecord::RecordNotUnique" do
    with_health_service_raising(ActiveRecord::RecordNotUnique.new("Duplicate record")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :conflict, expected_code: "conflict")
    end
  end

  test "409 conflict on ActiveRecord::StaleObjectError" do
    with_health_service_raising(ActiveRecord::StaleObjectError.new(Letter.new, :update)) do
      get "/api/v1/health"

      json = assert_error_response(expected_status: :conflict, expected_code: "conflict")
      assert_match(/modified by another request/i, json["error"]["message"])
    end
  end

  test "422 validation_failed on ActiveRecord::RecordInvalid with details" do
    letter = Letter.new
    letter.validate
    with_health_service_raising(ActiveRecord::RecordInvalid.new(letter)) do
      get "/api/v1/health"

      json = assert_error_response(expected_status: :unprocessable_content, expected_code: "validation_failed")
      assert json["error"].key?("details")
      assert_kind_of Hash, json["error"]["details"]
    end
  end

  test "429 rate_limited on Api::RateLimitedError" do
    with_health_service_raising(Api::RateLimitedError.new("Rate limit reached")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :too_many_requests, expected_code: "rate_limited")
    end
  end

  test "429 rate_limited via Rack::Attack throttled_responder" do
    req = Rack::MockRequest.env_for("/api/v1/letters", {
      "rack.attack.match_data" => { epoch_time: 1_700_000_000, period: 60 },
      "action_dispatch.request_id" => "mock-req-429",
      "HTTP_ACCEPT" => "application/json"
    })
    status, headers, body = Rack::Attack.throttled_responder.call(Rack::Attack::Request.new(req))

    assert_equal 429, status
    assert_equal "application/json; charset=utf-8", headers["Content-Type"]
    assert headers["Retry-After"].present?

    parsed = JSON.parse(body.first)
    assert_equal "rate_limited", parsed["error"]["code"]
    assert_equal "mock-req-429", parsed["error"]["requestId"]
  end

  test "500 internal_error in development exposes exception message" do
    with_health_service_raising(RuntimeError.new("Unexpected standard error")) do
      get "/api/v1/health"

      json = assert_error_response(expected_status: :internal_server_error, expected_code: "internal_error")
      assert_equal "Unexpected standard error", json["error"]["message"]
    end
  end

  test "500 internal_error in production masks internal message and backtrace" do
    original_env = Rails.env
    begin
      Rails.env = "production"
      with_health_service_raising(RuntimeError.new("Unexpected standard error")) do
        get "/api/v1/health"

        json = assert_error_response(expected_status: :internal_server_error, expected_code: "internal_error")
        assert_equal "Internal server error", json["error"]["message"]
        assert_nil json["error"]["backtrace"]
        refute_includes response.body, "Unexpected standard error"
      end
    ensure
      Rails.env = original_env
    end
  end

  test "503 service_unavailable on Api::ServiceUnavailableError" do
    with_health_service_raising(Api::ServiceUnavailableError.new("Upstream service timeout")) do
      get "/api/v1/health"

      assert_error_response(expected_status: :service_unavailable, expected_code: "service_unavailable")
    end
  end

  test "exceptions_app formats exceptions outside controller dispatch with error contract" do
    env = Rack::MockRequest.env_for("/api/v1/middleware_failure", {
      "action_dispatch.exception" => StandardError.new("Middleware crashed"),
      "action_dispatch.request_id" => "middleware-req-500"
    })
    status, headers, body = Api::V1::ExceptionsController.action(:show).call(env)

    assert_equal 500, status
    assert_match(%r{application/json}, headers["Content-Type"])
    parsed = JSON.parse(body.body)
    assert_equal "internal_error", parsed["error"]["code"]
    assert_equal "middleware-req-500", parsed["error"]["requestId"]
  end

  test "exceptions_app in production masks 500 error message" do
    original_env = Rails.env
    begin
      Rails.env = "production"
      env = Rack::MockRequest.env_for("/api/v1/middleware_failure", {
        "action_dispatch.exception" => StandardError.new("Middleware crashed"),
        "action_dispatch.request_id" => "middleware-req-500-prod"
      })
      status, _headers, body = Api::V1::ExceptionsController.action(:show).call(env)

      assert_equal 500, status
      parsed = JSON.parse(body.body)
      assert_equal "Internal server error", parsed["error"]["message"]
      assert_equal "internal_error", parsed["error"]["code"]
    ensure
      Rails.env = original_env
    end
  end
end
