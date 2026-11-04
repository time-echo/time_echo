# frozen_string_literal: true

module Api
  class ForbiddenError < ApiError
    def initialize(message = nil, details: nil)
      super(message || "Forbidden", status: :forbidden, code: "forbidden", details: details)
    end
  end
end
