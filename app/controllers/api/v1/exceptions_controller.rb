# frozen_string_literal: true

module Api
  module V1
    class ExceptionsController < ActionController::API
      STATUS_CODES = {
        400 => "bad_request",
        401 => "unauthorized",
        403 => "forbidden",
        404 => "not_found",
        406 => "not_acceptable",
        409 => "conflict",
        422 => "validation_failed",
        429 => "rate_limited",
        503 => "service_unavailable"
      }.freeze

      def show
        exception = request.env["action_dispatch.exception"]
        wrapper = ActionDispatch::ExceptionWrapper.new(request.env, exception)
        status_code = wrapper.status_code

        code = error_code_for_status(status_code)
        message = if Rails.env.production? && status_code >= 500
          "Internal server error"
        else
          exception&.message.presence || Rack::Utils::HTTP_STATUS_CODES[status_code] || "Error"
        end

        payload = {
          error: {
            code: code,
            message: message,
            requestId: request.request_id
          }
        }

        render json: payload, status: status_code
      end

      private

      def error_code_for_status(status_code)
        STATUS_CODES.fetch(status_code, "internal_error")
      end
    end
  end
end
