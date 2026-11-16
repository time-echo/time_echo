# frozen_string_literal: true

module Api
  class ServiceUnavailableError < ApiError
    def initialize(message = nil, details: nil)
      super(
        message || "Service temporarily unavailable. Please retry later.",
        status: :service_unavailable,
        code: "service_unavailable",
        details: details
      )
    end
  end
end
