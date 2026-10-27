# frozen_string_literal: true

class NotFoundError < ApiError
  def initialize(message = nil, details: nil)
    super(message || "Resource not found", status: :not_found, code: "not_found", details: details)
  end
end

module Api
  NotFoundError = ::NotFoundError
end
