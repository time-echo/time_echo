# frozen_string_literal: true

require "test_helper"

class Api::V1::ResultHandlerTest < ActiveSupport::TestCase
  class DummyResultClass
    include Api::ResultHandler
  end

  setup do
    @handler = DummyResultClass.new
  end

  test "unwrap! returns value when result is successful" do
    result = Struct.new(:success?, :letter).new(true, "LetterRecord")
    assert_equal "LetterRecord", @handler.unwrap!(result)
  end

  test "unwrap! raises Api::NotFoundError on :not_found" do
    result = Struct.new(:success?, :error, :message).new(false, :not_found, nil)
    err = assert_raises(Api::NotFoundError) { @handler.unwrap!(result) }
    assert_equal "not_found", err.code
    assert_equal 404, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::UnauthorizedError on :unauthorized (401 unauthorized)" do
    result = Struct.new(:success?, :error, :message).new(false, :unauthorized, nil)
    err = assert_raises(Api::UnauthorizedError) { @handler.unwrap!(result) }
    assert_equal "unauthorized", err.code
    assert_equal 401, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::ForbiddenError on :forbidden (403 forbidden)" do
    result = Struct.new(:success?, :error, :message).new(false, :forbidden, nil)
    err = assert_raises(Api::ForbiddenError) { @handler.unwrap!(result) }
    assert_equal "forbidden", err.code
    assert_equal 403, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::BusinessRuleError on :cannot_delete" do
    result = Struct.new(:success?, :error, :message).new(false, :cannot_delete, nil)
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "cannot_delete", err.code
    assert_equal 422, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::BusinessRuleError on :cannot_archive_delivered" do
    result = Struct.new(:success?, :error, :message).new(false, :cannot_archive_delivered, nil)
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "cannot_archive_delivered", err.code
    assert_equal 422, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::BusinessRuleError on :cannot_restore" do
    result = Struct.new(:success?, :error, :message).new(false, :cannot_restore, nil)
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "cannot_restore", err.code
    assert_equal 422, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::BusinessRuleError on :invalid" do
    result = Struct.new(:success?, :error, :message).new(false, :invalid, "Invalid data")
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "validation_failed", err.code
    assert_equal "Invalid data", err.message
    assert_equal 422, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::UnauthorizedError on :invalid_token" do
    result = Struct.new(:success?, :error, :message).new(false, :invalid_token, nil)
    err = assert_raises(Api::UnauthorizedError) { @handler.unwrap!(result) }
    assert_equal "unauthorized", err.code
    assert_equal 401, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises Api::RateLimitedError on :rate_limited" do
    result = Struct.new(:success?, :error, :message).new(false, :rate_limited, nil)
    err = assert_raises(Api::RateLimitedError) { @handler.unwrap!(result) }
    assert_equal "rate_limited", err.code
    assert_equal 429, Rack::Utils.status_code(err.status)
  end

  test "unwrap! raises ActiveRecord::RecordInvalid when result letter has errors" do
    letter = Letter.new
    letter.validate
    result = Struct.new(:success?, :error, :letter).new(false, nil, letter)
    assert_raises(ActiveRecord::RecordInvalid) { @handler.unwrap!(result) }
  end

  test "unwrap! raises Api::BusinessRuleError with custom code on unmapped symbol" do
    result = Struct.new(:success?, :error, :message).new(false, :quota_exceeded, "Monthly limit reached")
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "quota_exceeded", err.code
    assert_equal "Monthly limit reached", err.message
  end

  test "unwrap! returns value when result responds to value" do
    result = Struct.new(:success?, :value).new(true, "CustomValue")
    assert_equal "CustomValue", @handler.unwrap!(result)
  end

  test "unwrap! returns result itself when result responds to neither letter nor value" do
    result = Struct.new(:success?).new(true)
    assert_equal result, @handler.unwrap!(result)
  end

  test "unwrap! raises Api::BusinessRuleError on :invalid with default message when message is nil" do
    result = Struct.new(:success?, :error, :message).new(false, :invalid, nil)
    err = assert_raises(Api::BusinessRuleError) { @handler.unwrap!(result) }
    assert_equal "validation_failed", err.code
    assert err.message.present?
  end

  test "Api::ApiError uses default message when none provided" do
    err = Api::ApiError.new
    assert_equal "An API error occurred", err.message
    assert_equal "internal_error", err.code
    assert_equal :internal_server_error, err.status
  end
end
