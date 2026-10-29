# frozen_string_literal: true

module Api
  class BusinessRuleError < ApiError
    def initialize(message = nil, code: "unprocessable_content", details: nil)
      super(message || "Business rule violation", status: :unprocessable_content, code: code, details: details)
    end
  end
end
