# frozen_string_literal: true

module Api
  class UnauthorizedError < ApiError
    def initialize(message = nil, details: nil)
      super(message || "Unauthorized", status: :unauthorized, code: "unauthorized", details: details)
    end
  end
end
