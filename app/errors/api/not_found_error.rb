# frozen_string_literal: true

module Api
  class NotFoundError < ApiError
    def initialize(message = nil, details: nil)
      message ||= I18n.t("flash.private_or_inaccessible", default: "Resource not found")
      super(message, status: :not_found, code: "not_found", details: details)
    end
  end
end
