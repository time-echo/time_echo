# frozen_string_literal: true

module Api
  module ErrorHandler
    extend ActiveSupport::Concern

    included do
      # Evaluated bottom-to-top by Rails. StandardError is registered first so more specific handlers take precedence.
      rescue_from StandardError, with: :handle_standard_error
      rescue_from ApiError, with: :handle_api_error
      rescue_from ActiveRecord::RecordNotFound, with: :handle_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :handle_record_invalid
      rescue_from ActiveRecord::RecordNotUnique, with: :handle_record_not_unique
      rescue_from ActionDispatch::Http::Parameters::ParseError, with: :handle_bad_request
      rescue_from ActionController::ParameterMissing, with: :handle_parameter_missing

      if defined?(Pundit::NotAuthorizedError)
        rescue_from Pundit::NotAuthorizedError, with: :handle_forbidden
      end

      if defined?(CanCan::AccessDenied)
        rescue_from CanCan::AccessDenied, with: :handle_forbidden
      end
    end

    def handle_service_result!(result, message_fallbacks = {})
      return result if result.success?

      handle_service_error!(result, message_fallbacks)
    end

    def handle_service_error!(result, message_fallbacks = {})
      error_key = result.error
      message = service_error_message(result) || message_fallbacks[error_key]

      case error_key
      when :not_found
        raise Api::NotFoundError, message || I18n.t("flash.private_or_inaccessible")
      when :unauthorized
        raise Api::UnauthorizedError, message || I18n.t("flash.unauthorized_action")
      else
        if result.respond_to?(:letter) && result.letter&.errors&.any?
          raise ActiveRecord::RecordInvalid, result.letter
        elsif result.respond_to?(:errors) && result.errors.present?
          raise Api::BusinessRuleError.new(
            result.errors.full_messages.to_sentence,
            code: "validation_failed",
            details: result.errors.to_hash
          )
        else
          code = (error_key || "business_rule_violation").to_s
          fallback_msg = I18n.t("flash.#{code}", default: code.humanize)
          raise Api::BusinessRuleError.new(message || fallback_msg, code: code)
        end
      end
    end

    private

    def service_error_message(result)
      result.message if result.respond_to?(:message) && result.message.present?
    end

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

    def handle_record_invalid(exception)
      render_error(
        status: :unprocessable_entity,
        code: "validation_failed",
        message: exception.record.errors.full_messages.to_sentence,
        details: exception.record.errors.to_hash
      )
    end

    def handle_record_not_unique(exception)
      render_error(
        status: :conflict,
        code: "conflict",
        message: "A record with these details already exists or violates a uniqueness constraint"
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

    def handle_forbidden(exception)
      render_error(
        status: :forbidden,
        code: "forbidden",
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
