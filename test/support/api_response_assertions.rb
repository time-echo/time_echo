# frozen_string_literal: true

module ApiResponseAssertions
  def assert_resource_response(expected_status: :ok)
    assert_response expected_status
    body = JSON.parse(response.body)

    assert body.key?("data"), "Expected response body to contain 'data' key"
    assert body.key?("meta"), "Expected response body to contain 'meta' key"
    assert_kind_of Hash, body["data"], "Expected 'data' to be a Hash for single resource"
    assert_kind_of Hash, body["meta"], "Expected 'meta' to be a Hash"
    body
  end

  def assert_collection_response(expected_status: :ok)
    assert_response expected_status
    body = JSON.parse(response.body)

    assert body.key?("data"), "Expected response body to contain 'data' key"
    assert body.key?("meta"), "Expected response body to contain 'meta' key"
    assert_kind_of Array, body["data"], "Expected 'data' to be an Array for collection"
    assert_kind_of Hash, body["meta"], "Expected 'meta' to be a Hash"

    meta = body["meta"]
    assert meta.key?("page"), "Expected meta to contain 'page'"
    assert meta.key?("perPage"), "Expected meta to contain 'perPage'"
    assert meta.key?("total"), "Expected meta to contain 'total'"
    assert meta.key?("totalPages"), "Expected meta to contain 'totalPages'"
    body
  end

  def assert_error_response(expected_status:, expected_code:)
    assert_response expected_status
    body = JSON.parse(response.body)

    assert body.key?("error"), "Expected response body to contain 'error' key"
    error = body["error"]
    assert_kind_of Hash, error, "Expected 'error' to be a Hash"
    assert error.key?("code"), "Expected error to contain 'code'"
    assert error.key?("message"), "Expected error to contain 'message'"
    assert error.key?("requestId"), "Expected error to contain 'requestId'"

    assert_equal expected_code.to_s, error["code"], "Expected error code '#{expected_code}', got '#{error['code']}'"
    assert error["message"].present?, "Expected error message to be present"
    assert error["requestId"].present?, "Expected error requestId to be present"
    body
  end
end
