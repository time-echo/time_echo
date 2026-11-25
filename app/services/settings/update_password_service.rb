# frozen_string_literal: true

module Settings
  class UpdatePasswordService
    def self.call(email:, password:, current_password: nil, password_confirmation: nil, current_token: nil)
      new(
        email: email,
        password: password,
        current_password: current_password,
        password_confirmation: password_confirmation,
        current_token: current_token
      ).call
    end

    def initialize(email:, password:, current_password: nil, password_confirmation: nil, current_token: nil)
      @email = email.to_s.strip.downcase
      @password = password.to_s
      @current_password = current_password
      @password_confirmation = password_confirmation
      @current_token = current_token
    end

    def call
      user = User.find_or_create_for_email!(@email)

      if user.has_password?
        unless @current_password.present? && user.authenticate(@current_password.to_s)
          return ServiceResult.failure(
            :invalid_current_password,
            message: I18n.t("settings.invalid_current_password")
          )
        end
      end

      if @password.blank?
        user.errors.add(:password, :blank)
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      ActiveRecord::Base.transaction do
        user.password = @password
        user.password_confirmation = @password_confirmation unless @password_confirmation.nil?

        unless user.save
          raise ActiveRecord::Rollback
        end

        revoke_other_sessions(user.email)
        AuditLog.record!(
          action: "account.password_updated",
          actor_email: user.email
        )
      end

      if user.errors.any?
        return ServiceResult.failure(:invalid, errors: user.errors)
      end

      ServiceResult.success(
        {
          message: I18n.t("settings.password_updated")
        }
      )
    end

    Result = ServiceResult

    private

    def revoke_other_sessions(email)
      scope = SessionToken.active.where(email: email)
      scope = scope.where.not(token: @current_token) if @current_token.present?
      scope.update_all(used_at: Time.current, updated_at: Time.current)
    end
  end
end
