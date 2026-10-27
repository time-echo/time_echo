# frozen_string_literal: true

module Api
  module ErrorHandler
    extend ActiveSupport::Concern

    included do
      # Evaluated bottom-to-top by Rails. StandardError declared first so specific handlers take precedence.
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ServiceUnavailableError, with: :handle_service_unavailable
      rescue_from RateLimitedError, with: :handle_rate_limited
      rescue_from ApiError, with: :handle_api_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActionController::UnknownFormat, with: :handle_unknown_format
      rescue_from ActiveRecord::RecordNotUnique, with: :handle_conflict
      rescue_from ActiveRecord::StaleObjectError, with: :handle_conflict
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
      rescue_from ForbiddenError, with: :handle_forbidden
      rescue_from UnauthorizedError, with: :handle_unauthorized
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_bad_request
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

      if defined?(Pundit::NotAuthorizedError)
        rescue_from Pundit::NotAuthorizedError, with: :handle_forbidden
      end

      if defined?(CanCan::AccessDenied)
        rescue_from CanCan::AccessDenied, with: :handle_forbidden
      end
    end

    private

    def handle_standard_error(exception)
      log_exception(exception)
      capture_sentry_exception(exception)

      message = if Rails.env.production?
        "Internal server error"
      else
        exception.message
      end

      render_error(
        status: :internal_server_error,
        code: "internal_error",
        message: message
      )
    end

    def handle_service_unavailable(exception)
      render_error(
        status: :service_unavailable,
        code: "service_unavailable",
        message: exception.message,
        details: exception.details
      )
    end

    def handle_rate_limited(exception)
      render_error(
        status: :too_many_requests,
        code: "rate_limited",
        message: exception.message,
        details: exception.details
      )
    end

    def handle_api_error(exception)
      render_error(
        status: exception.status,
        code: exception.code,
        message: exception.message,
        details: exception.details
      )
    end

    def handle_not_found(exception)
      render_error(
        status: :not_found,
        code: "not_found",
        message: exception.message
      )
    end

    def handle_unknown_format(exception)
      render_error(
        status: :not_acceptable,
        code: "not_acceptable",
        message: exception.message
      )
    end

    def handle_conflict(exception)
      message = if exception.is_a?(ActiveRecord::StaleObjectError)
        "Record was modified by another request. Please reload and retry."
      else
        "A record with these details already exists or violates a uniqueness constraint"
      end

      render_error(
        status: :conflict,
        code: "conflict",
        message: message
      )
    end

    def handle_record_invalid(exception)
      render_error(
        status: :unprocessable_entity,
        code: "validation_failed",
        message: exception.record.errors.full_messages.to_sentence,
        details: exception.record.errors.to_hash
      )
    end

    def handle_unauthorized(exception)
      render_error(
        status: :unauthorized,
        code: "unauthorized",
        message: exception.message,
        details: exception.details
      )
    end

    def handle_forbidden(exception)
      render_error(
        status: :forbidden,
        code: "forbidden",
        message: exception.message,
        details: exception.details
      )
    end

    def handle_bad_request(exception)
      render_error(
        status: :bad_request,
        code: "bad_request",
        message: "Invalid or malformed request parameters"
      )
    end

    def handle_parameter_missing(exception)
      render_error(
        status: :bad_request,
        code: "bad_request",
        message: exception.message
      )
    end

    def render_error(status:, code:, message:, details: nil)
      @error_code = code.to_s
      @error_message = message
      @error_details = details
      @request_id = request&.request_id

      render "api/v1/shared/error", status: status
    end

    def log_exception(exception)
      req_id = request&.request_id
      Rails.logger.error("[#{req_id}] 500 Internal Server Error: #{exception.class} - #{exception.message}")
      Rails.logger.error(exception.backtrace&.join("\n")) if exception.backtrace
    end

    def capture_sentry_exception(exception)
      if defined?(Sentry) && Sentry.respond_to?(:capture_exception)
        Sentry.capture_exception(exception)
      end
    end
  end
end
