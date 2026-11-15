# frozen_string_literal: true

module Settings
  class ConfirmEmailUpdateService
    def self.call(token)
      new(token).call
    end

    def initialize(token)
      @token = token
    end

    def call
      invalid_msg = I18n.t("settings.confirmation_link_invalid")
      return Result.new(success: false, error: :invalid_token, message: invalid_msg) if @token.blank?

      payload = Rails.application.message_verifier(:email_update).verified(@token)
      return Result.new(success: false, error: :invalid_token, message: invalid_msg) unless payload.is_a?(Hash)

      old_email = payload[:old_email] || payload["old_email"]
      new_email = payload[:new_email] || payload["new_email"]

      return Result.new(success: false, error: :invalid_token, message: invalid_msg) if old_email.blank? || new_email.blank?

      ActiveRecord::Base.transaction do
        Letter.where(email: old_email).update_all(email: new_email)
        SessionToken.where(email: old_email).update_all(email: new_email)
        AuditLog.record!(
          action: "account.email_updated",
          actor_email: new_email,
          metadata: { old_email: old_email, new_email: new_email }
        )
      end

      Analytics::TrackEventService.call("email_update_confirmed", { old_email: old_email, new_email: new_email })

      Result.new(
        success: true,
        new_email: new_email,
        value: {
          email: new_email,
          message: I18n.t("settings.email_confirmed")
        }
      )
    end

    class Result
      attr_reader :new_email, :value, :error, :message

      def initialize(success:, new_email: nil, value: nil, error: nil, message: nil)
        @success = success
        @new_email = new_email
        @value = value
        @error = error
        @message = message
      end

      def success?
        @success
      end
    end
  end
end
