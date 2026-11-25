# frozen_string_literal: true

module Oauth
  class CompleteLoginService
    def self.call(provider:, code:, state:)
      new(provider: provider, code: code, state: state).call
    end

    def initialize(provider:, code:, state:)
      @provider = provider.to_s.strip.downcase
      @code = code.to_s.strip
      @state = state.to_s.strip
    end

    def call
      provider_client = ProviderRegistry.fetch(@provider)
      return ServiceResult.failure(:invalid_provider, message: I18n.t("flash.oauth_invalid_provider")) if provider_client.nil?

      oauth_state = OauthState.consume!(raw_state: @state, provider: @provider)
      return ServiceResult.failure(:invalid_token, message: I18n.t("flash.oauth_invalid_state")) if oauth_state.nil?
      return ServiceResult.failure(:oauth_failed, message: I18n.t("flash.oauth_failed")) if @code.blank?

      redirect_uri = Providers::Base.redirect_uri_for(@provider)
      profile = provider_client.fetch_profile(
        code: @code,
        code_verifier: oauth_state.code_verifier,
        redirect_uri: redirect_uri
      )

      if oauth_state.purpose == "link"
        return Oauth::LinkIdentityService.call(user: oauth_state.user, provider: @provider, profile: profile)
      end

      resolve_login_for_profile(profile)
    rescue Providers::Base::ProviderError => e
      ServiceResult.failure(e.code, message: e.message)
    end

    Result = ServiceResult

    private

    def resolve_login_for_profile(profile)
      identity = Identity.find_by(provider: @provider, uid: profile[:uid])
      if identity.present?
        identity.update!(email: profile[:email]) if profile[:email].present? && identity.email != profile[:email]
        return issue_oauth_session(identity.user, is_new_user: false)
      end

      email = profile[:email]
      if email.blank?
        return ServiceResult.failure(:email_required, message: I18n.t("flash.oauth_email_required"))
      end

      existing_user = User.find_by(email: email)
      if existing_user.present?
        unless profile[:email_verified]
          return ServiceResult.failure(:unverified_provider_email, message: I18n.t("flash.oauth_unverified_email"))
        end

        ActiveRecord::Base.transaction do
          existing_user.update!(email_verified_at: Time.current) if existing_user.email_verified_at.nil?
          existing_user.identities.create!(
            provider: @provider,
            uid: profile[:uid],
            email: email
          )
        end

        return issue_oauth_session(existing_user, is_new_user: false)
      end

      user = nil
      ActiveRecord::Base.transaction do
        user = User.create!(
          email: email,
          email_verified_at: profile[:email_verified] ? Time.current : nil
        )
        user.identities.create!(
          provider: @provider,
          uid: profile[:uid],
          email: email
        )
      end

      issue_oauth_session(user, is_new_user: true)
    end

    def issue_oauth_session(user, is_new_user:)
      result = Auth::IssueSessionService.call(
        user: user,
        auth_method: "oauth_#{@provider}",
        is_new_user: is_new_user
      )
      return result if result.failure?

      ServiceResult.success(result.value.merge(purpose: "login", provider: @provider))
    end
  end
end
