# frozen_string_literal: true

class ForbiddenError < ApiError
  def initialize(message = nil, details: nil)
    super(message || "Forbidden", status: :forbidden, code: "forbidden", details: details)
  end
end

module Api
  ForbiddenError = ::ForbiddenError
end
