# frozen_string_literal: true

class BusinessRuleError < ApiError
  def initialize(message = nil, code: "business_rule_violation", status: :unprocessable_entity, details: nil)
    super(message || "Business rule violated", status: status, code: code, details: details)
  end
end

module Api
  BusinessRuleError = ::BusinessRuleError
end
