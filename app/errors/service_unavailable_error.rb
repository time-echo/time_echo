# frozen_string_literal: true

class ServiceUnavailableError < ApiError
  def initialize(message = nil, details: nil)
    super(message || "Service temporarily unavailable. Please try again later.", status: :service_unavailable, code: "service_unavailable", details: details)
  end
end

module Api
  ServiceUnavailableError = ::ServiceUnavailableError
end
