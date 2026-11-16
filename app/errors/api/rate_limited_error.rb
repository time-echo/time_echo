# frozen_string_literal: true

module Api
  class RateLimitedError < ApiError
    def initialize(message = nil, details: nil)
      super(
        message || "Rate limit exceeded. Please retry later.",
        status: :too_many_requests,
        code: "rate_limited",
        details: details
      )
    end
  end
end
