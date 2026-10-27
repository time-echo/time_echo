# frozen_string_literal: true

class ApiError < StandardError
  attr_reader :status, :code, :details

  def initialize(message = nil, status: :internal_server_error, code: "internal_error", details: nil)
    @status = status
    @code = code.to_s
    @details = details
    super(message || default_message)
  end

  private

  def default_message
    "An API error occurred"
  end
end

module Api
  ApiError = ::ApiError
end
