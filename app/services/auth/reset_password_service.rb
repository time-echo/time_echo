# frozen_string_literal: true

module Auth
  class ResetPasswordService
    def self.call(token:, password:, password_confirmation: nil)
      new(
        token: token,
        password: password,
        password_confirmation: password_confirmation
      ).call
    end

    def initialize(token:, password:, password_confirmation: nil)
      @token = token.to_s.strip
      @password = password.to_s
      @password_confirmation = password_confirmation
    end

    def call
      user = User.find_by_reset_token(@token)
      if user.nil?
        return ServiceResult.failure(
          :invalid_token,
          message: I18n.t("flash.invalid_reset_token")
        )
      end

      if @password.blank?
        user.errors.add(:password, :blank)
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      ActiveRecord::Base.transaction do
        user.password = @password
        user.password_confirmation = @password_confirmation unless @password_confirmation.nil?
        user.email_verified_at ||= Time.current
        user.reset_token_digest = nil
        user.reset_sent_at = nil

        unless user.save
          raise ActiveRecord::Rollback
        end

        SessionToken.revoke_active_for(user.email)
        AuditLog.record!(
          action: "account.password_reset",
          actor_email: user.email
        )
      end

      if user.errors.any?
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      ServiceResult.success(
        {
          message: I18n.t("flash.password_reset_success")
        }
      )
    end

    Result = ServiceResult
  end
end
