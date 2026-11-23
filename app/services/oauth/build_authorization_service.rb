# frozen_string_literal: true

module Oauth
  class BuildAuthorizationService
    def self.call(provider:, purpose: "login", user_email: nil)
      new(provider: provider, purpose: purpose, user_email: user_email).call
    end

    def initialize(provider:, purpose: "login", user_email: nil)
      @provider = provider.to_s.strip.downcase
      @purpose = purpose.to_s.strip.downcase
      @user_email = user_email
    end

    def call
      provider_client = ProviderRegistry.fetch(@provider)
      return ServiceResult.failure(:invalid_provider, message: I18n.t("flash.oauth_invalid_provider")) if provider_client.nil?

      user = nil
      if @purpose == "link"
        return ServiceResult.failure(:unauthorized, message: I18n.t("flash.login_required")) if @user_email.blank?

        user = User.find_or_create_for_email!(@user_email)
      end

      raw_state, oauth_state = OauthState.create_for!(
        provider: @provider,
        purpose: @purpose == "link" ? "link" : "login",
        user: user
      )

      redirect_uri = Providers::Base.redirect_uri_for(@provider)
      url = provider_client.authorization_url(
        state: raw_state,
        code_challenge: oauth_state.code_challenge,
        redirect_uri: redirect_uri
      )

      ServiceResult.success(
        {
          provider: @provider,
          url: url
        }
      )
    rescue Providers::Base::ProviderError => e
      ServiceResult.failure(e.code, message: e.message)
    end

    Result = ServiceResult
  end
end
