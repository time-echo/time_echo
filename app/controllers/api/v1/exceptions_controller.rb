# frozen_string_literal: true

module Api
  module V1
    class ExceptionsController < ActionController::API
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
        case status_code
        when 400 then "bad_request"
        when 401 then "unauthorized"
        when 403 then "forbidden"
        when 404 then "not_found"
        when 406 then "not_acceptable"
        when 409 then "conflict"
        when 422 then "validation_failed"
        when 429 then "rate_limited"
        when 503 then "service_unavailable"
        else "internal_error"
        end
      end
    end
  end
end
