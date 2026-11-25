# frozen_string_literal: true

module Oauth
  class UnlinkIdentityService
    def self.call(email:, provider:)
      new(email: email, provider: provider).call
    end

    def initialize(email:, provider:)
      @email = email.to_s.strip.downcase
      @provider = provider.to_s.strip.downcase
    end

    def call
      user = User.find_by(email: @email)
      return ServiceResult.failure(:not_found, message: I18n.t("settings.identity_not_found")) if user.nil?

      identity = user.identities.find_by(provider: @provider)
      return ServiceResult.failure(:not_found, message: I18n.t("settings.identity_not_found")) if identity.nil?

      if user.login_methods_count <= 1
        return ServiceResult.failure(:last_login_method, message: I18n.t("settings.cannot_unlink_last_method"))
      end

      ActiveRecord::Base.transaction do
        identity.destroy!
        AuditLog.record!(
          action: "account.identity_unlinked",
          actor_email: user.email,
          metadata: { provider: @provider }
        )
      end

      ServiceResult.success(
        {
          provider: @provider,
          unlinked: true,
          message: I18n.t("settings.identity_unlinked")
        }
      )
    end

    Result = ServiceResult
  end
end
