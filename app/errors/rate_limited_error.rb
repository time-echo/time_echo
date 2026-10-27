# frozen_string_literal: true

class RateLimitedError < ApiError
  def initialize(message = nil, details: nil)
    super(message || "Too many requests. Please try again later.", status: :too_many_requests, code: "rate_limited", details: details)
  end
end

module Api
  RateLimitedError = ::RateLimitedError
end
