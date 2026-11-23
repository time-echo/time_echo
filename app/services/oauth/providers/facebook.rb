# frozen_string_literal: true

module Oauth
  module Providers
    class Facebook < Base
      AUTHORIZE_URL = "https://www.facebook.com/v21.0/dialog/oauth"
      TOKEN_URL = "https://graph.facebook.com/v21.0/oauth/access_token"
      PROFILE_URL = "https://graph.facebook.com/v21.0/me"

      def authorization_url(state:, code_challenge:, redirect_uri:)
        ensure_configured!

        query = URI.encode_www_form(
          client_id: app_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: "email,public_profile",
          state: state,
          code_challenge: code_challenge,
          code_challenge_method: "S256"
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def fetch_profile(code:, code_verifier:, redirect_uri:)
        ensure_configured!

        token_data = http_get_json(
          TOKEN_URL,
          params: {
            client_id: app_id,
            client_secret: app_secret,
            redirect_uri: redirect_uri,
            code: code,
            code_verifier: code_verifier
          }
        )

        access_token = token_data["access_token"]
        raise ProviderError.new("Missing access token from Facebook", code: :oauth_failed) if access_token.blank?

        profile = http_get_json(
          PROFILE_URL,
          params: { fields: "id,name,email" },
          headers: { "Authorization" => "Bearer #{access_token}" }
        )

        uid = profile["id"].to_s
        raise ProviderError.new("Missing Facebook user identifier", code: :oauth_failed) if uid.blank?

        email = profile["email"]&.strip&.downcase.presence
        raise ProviderError.new(I18n.t("flash.oauth_email_required"), code: :email_required) if email.blank?

        {
          uid: uid,
          email: email,
          email_verified: true,
          name: profile["name"]
        }
      end

      private

      def app_id
        fetch_credential("FACEBOOK_APP_ID", :facebook, :app_id)
      end

      def app_secret
        fetch_credential("FACEBOOK_APP_SECRET", :facebook, :app_secret)
      end

      def ensure_configured!
        return if app_id.present? && app_secret.present?

        raise ProviderError.new("Facebook OAuth is not configured", code: :oauth_not_configured)
      end
    end
  end
end
