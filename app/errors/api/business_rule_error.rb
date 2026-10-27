# frozen_string_literal: true

module Api
  class BusinessRuleError < ApiError
    def initialize(message = nil, code: "unprocessable_entity", details: nil)
      super(message || "Business rule violation", status: :unprocessable_entity, code: code, details: details)
    end
  end
end
