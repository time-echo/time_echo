# frozen_string_literal: true

module Api
  module ResultHandler
    extend ActiveSupport::Concern

    RESULT_ERRORS = {
      not_found: {
        exception_class: Api::NotFoundError,
        default_message: -> { I18n.t("flash.private_or_inaccessible", default: "Resource not found") }
      },
      unauthorized: {
        exception_class: Api::UnauthorizedError,
        default_message: -> { I18n.t("flash.unauthorized_action", default: "You are not authorized to perform this action") }
      },
      forbidden: {
        exception_class: Api::ForbiddenError,
        default_message: -> { I18n.t("flash.unauthorized_action", default: "You are not authorized to perform this action") }
      },
      cannot_delete: {
        exception_class: Api::BusinessRuleError,
        code: "cannot_delete",
        default_message: -> { I18n.t("flash.cannot_delete", default: "Cannot delete letter") }
      },
      cannot_archive_delivered: {
        exception_class: Api::BusinessRuleError,
        code: "cannot_archive_delivered",
        default_message: -> { I18n.t("flash.cannot_archive_delivered", default: "Cannot archive delivered letter") }
      },
      cannot_restore: {
        exception_class: Api::BusinessRuleError,
        code: "cannot_restore",
        default_message: -> { I18n.t("flash.cannot_restore", default: "Cannot restore letter") }
      },
      invalid: {
        exception_class: Api::BusinessRuleError,
        code: "validation_failed",
        default_message: -> { I18n.t("letters.error_saving", default: "Validation failed") }
      },
      invalid_token: {
        exception_class: Api::UnauthorizedError,
        default_message: -> { I18n.t("flash.invalid_link", default: "Invalid or expired link") }
      },
      invalid_credentials: {
        exception_class: Api::UnauthorizedError,
        default_message: -> { I18n.t("flash.invalid_credentials", default: "Invalid email or password") }
      },
      invalid_current_password: {
        exception_class: Api::BusinessRuleError,
        code: "invalid_current_password",
        default_message: -> { I18n.t("settings.invalid_current_password", default: "Current password is incorrect") }
      },
      last_login_method: {
        exception_class: Api::BusinessRuleError,
        code: "last_login_method",
        default_message: -> { I18n.t("settings.cannot_unlink_last_method", default: "You cannot unlink your last sign-in method") }
      },
      email_required: {
        exception_class: Api::BusinessRuleError,
        code: "email_required",
        default_message: -> { I18n.t("flash.oauth_email_required", default: "Your social account must provide a verified email address") }
      },
      unverified_provider_email: {
        exception_class: Api::BusinessRuleError,
        code: "unverified_provider_email",
        default_message: -> { I18n.t("flash.oauth_unverified_email", default: "Please sign in with a magic link first to link this account") }
      },
      identity_already_linked: {
        exception_class: Api::BusinessRuleError,
        code: "identity_already_linked",
        default_message: -> { I18n.t("settings.identity_already_linked", default: "This social account is already linked") }
      },
      invalid_provider: {
        exception_class: Api::BusinessRuleError,
        code: "invalid_provider",
        default_message: -> { I18n.t("flash.oauth_invalid_provider", default: "Unsupported sign-in provider") }
      },
      oauth_failed: {
        exception_class: Api::UnauthorizedError,
        default_message: -> { I18n.t("flash.oauth_failed", default: "Social sign-in failed") }
      },
      oauth_not_configured: {
        exception_class: Api::ServiceUnavailableError,
        default_message: -> { I18n.t("flash.service_unavailable", default: "Service temporarily unavailable. Please retry later.") }
      },
      rate_limited: {
        exception_class: Api::RateLimitedError,
        default_message: -> { I18n.t("errors.messages.magic_link_rate_limit_exceeded", default: "Rate limit reached") }
      },
      service_unavailable: {
        exception_class: Api::ServiceUnavailableError,
        default_message: -> { I18n.t("flash.service_unavailable", default: "Service temporarily unavailable. Please retry later.") }
      }
    }.freeze

    def unwrap!(result)
      return extract_result_value(result) if result.success?

      raise_mapped_result_error!(result)
    end

    private

    def extract_result_value(result)
      if result.respond_to?(:letter) && result.letter.present?
        result.letter
      elsif result.respond_to?(:value)
        result.value
      else
        result
      end
    end

    def raise_mapped_result_error!(result)
      if result.respond_to?(:letter) && result.letter&.errors&.any?
        raise ActiveRecord::RecordInvalid, result.letter
      elsif result.respond_to?(:errors) && result.errors.present?
        raise Api::BusinessRuleError.new(
          result.errors.full_messages.to_sentence,
          code: "validation_failed",
          details: result.errors.to_hash
        )
      end

      error_key = result.respond_to?(:code) && result.code ? result.code : result.error
      config = RESULT_ERRORS[error_key]
      custom_message = result.message if result.respond_to?(:message) && result.message.present?
      details = result.details if result.respond_to?(:details)

      if config
        message = custom_message || config[:default_message].call
        if config[:exception_class] == Api::ServiceUnavailableError
          raise config[:exception_class].new(message, details: details)
        elsif config[:code]
          raise config[:exception_class].new(message, code: config[:code])
        else
          raise config[:exception_class], message
        end
      else
        code = (error_key || "business_rule_violation").to_s
        fallback_msg = custom_message || I18n.t("flash.#{code}", default: code.humanize)
        raise Api::BusinessRuleError.new(fallback_msg, code: code)
      end
    end
  end
end
