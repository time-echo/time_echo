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
      return ServiceResult.failure(:invalid_token, message: invalid_msg) if @token.blank?

      payload = Rails.application.message_verifier(:email_update).verified(@token)
      return ServiceResult.failure(:invalid_token, message: invalid_msg) unless payload.is_a?(Hash)

      old_email = payload[:old_email] || payload["old_email"]
      new_email = payload[:new_email] || payload["new_email"]

      return ServiceResult.failure(:invalid_token, message: invalid_msg) if old_email.blank? || new_email.blank?

      ActiveRecord::Base.transaction do
        Letter.where(email: old_email).update_all(email: new_email)
        SessionToken.where(email: old_email).update_all(email: new_email)
        User.where(email: old_email).update_all(email: new_email, email_verified_at: Time.current, updated_at: Time.current)
        AuditLog.record!(
          action: "account.email_updated",
          actor_email: new_email,
          metadata: { old_email: old_email, new_email: new_email }
        )
      end

      Analytics::TrackEventService.call("email_update_confirmed", { old_email: old_email, new_email: new_email })

      ServiceResult.success(
        {
          email: new_email,
          message: I18n.t("settings.email_confirmed")
        },
        new_email: new_email
      )
    end

    Result = ServiceResult
  end
end
