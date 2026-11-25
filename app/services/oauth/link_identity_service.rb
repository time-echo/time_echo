# frozen_string_literal: true

module Oauth
  class LinkIdentityService
    def self.call(user:, provider:, profile:)
      new(user: user, provider: provider, profile: profile).call
    end

    def initialize(user:, provider:, profile:)
      @user = user
      @provider = provider.to_s.strip.downcase
      @profile = profile
    end

    def call
      return ServiceResult.failure(:unauthorized, message: I18n.t("flash.login_required")) if @user.nil?

      existing_by_uid = Identity.find_by(provider: @provider, uid: @profile[:uid])
      if existing_by_uid.present? && existing_by_uid.user_id != @user.id
        return ServiceResult.failure(:identity_already_linked, message: I18n.t("settings.identity_already_linked"))
      end

      identity = @user.identities.find_by(provider: @provider)
      if identity.present?
        if identity.uid != @profile[:uid]
          return ServiceResult.failure(:identity_already_linked, message: I18n.t("settings.provider_already_linked"))
        end
        identity.update!(email: @profile[:email]) if @profile[:email].present?
      else
        @user.identities.create!(
          provider: @provider,
          uid: @profile[:uid],
          email: @profile[:email]
        )
      end

      AuditLog.record!(
        action: "account.identity_linked",
        actor_email: @user.email,
        metadata: { provider: @provider }
      )

      ServiceResult.success(
        {
          purpose: "link",
          provider: @provider,
          email: @profile[:email],
          linked: true
        }
      )
    end

    Result = ServiceResult
  end
end
