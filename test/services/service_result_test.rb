# frozen_string_literal: true

require "test_helper"

class ServiceResultTest < ActiveSupport::TestCase
  test "success factory creates a successful result" do
    result = ServiceResult.success({ message: "Dispatched" })

    assert result.success?
    assert_not result.failure?
    assert_equal({ message: "Dispatched" }, result.value)
    assert_nil result.error
    assert_equal "Dispatched", result[:message]
  end

  test "failure factory creates a failed result with error and message" do
    result = ServiceResult.failure(:not_found, message: "Resource missing", code: "missing_resource")

    assert_not result.success?
    assert result.failure?
    assert_equal :not_found, result.error
    assert_equal "Resource missing", result.message
    assert_equal "missing_resource", result.code
  end

  test "supports arbitrary metadata attributes dynamically" do
    result = ServiceResult.success(countdown: true, score: 98)

    assert result.success?
    assert result.countdown?
    assert_equal 98, result.score
  end

  test "provides backward compatibility helpers for letter and form" do
    form = Object.new
    result = ServiceResult.success(nil, form: form)

    assert_same form, result.form
  end
end
