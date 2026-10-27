# frozen_string_literal: true

require "test_helper"

class Api::V1::ErrorHandlingTest < ActionDispatch::IntegrationTest
  test "400 bad_request on ParameterMissing" do
    post "/api/v1/dummy/bad_request", params: {}

    json = assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
    assert_match(/required_param/i, json["error"]["message"])
  end

  test "400 bad_request on malformed JSON payload" do
    post "/api/v1/dummy/bad_request",
         headers: { "Content-Type" => "application/json" },
         env: { "RAW_POST_DATA" => "{\"invalid_json: true" }

    assert_error_response(expected_status: :bad_request, expected_code: "bad_request")
  end

  test "401 unauthorized when unauthenticated" do
    get "/api/v1/dummy/protected"

    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "403 forbidden" do
    get "/api/v1/dummy/forbidden"

    assert_error_response(expected_status: :forbidden, expected_code: "forbidden")
  end

  test "404 not_found on ActiveRecord::RecordNotFound" do
    get "/api/v1/dummy/error"

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "404 not_found on non-existent API route via catch-all" do
    get "/api/v1/unknown_resource"

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "409 conflict on ActiveRecord::RecordNotUnique" do
    get "/api/v1/dummy/conflict"

    assert_error_response(expected_status: :conflict, expected_code: "conflict")
  end

  test "422 validation_failed on ActiveRecord::RecordInvalid" do
    get "/api/v1/dummy/invalid"

    json = assert_error_response(expected_status: :unprocessable_entity, expected_code: "validation_failed")
    assert json["error"].key?("details")
    assert_kind_of Hash, json["error"]["details"]
  end

  test "500 internal_error in development exposes message" do
    get "/api/v1/dummy/server_error"

    json = assert_error_response(expected_status: :internal_server_error, expected_code: "internal_error")
    assert_equal "Unexpected standard error", json["error"]["message"]
  end

  test "500 internal_error in production masks internal message and backtrace" do
    original_env = Rails.env
    begin
      Rails.env = "production"
      get "/api/v1/dummy/server_error"

      json = assert_error_response(expected_status: :internal_server_error, expected_code: "internal_error")
      assert_equal "Internal server error", json["error"]["message"]
      assert_nil json["error"]["backtrace"]
      refute_includes response.body, "Unexpected standard error"
    ensure
      Rails.env = original_env
    end
  end
end
