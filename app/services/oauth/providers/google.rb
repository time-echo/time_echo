# frozen_string_literal: true

module Oauth
  module Providers
    class Google < Base
      AUTHORIZE_URL = "https://accounts.google.com/o/oauth2/v2/auth"
      TOKEN_URL = "https://oauth2.googleapis.com/token"
      USERINFO_URL = "https://openidconnect.googleapis.com/v1/userinfo"

      def authorization_url(state:, code_challenge:, redirect_uri:)
        ensure_configured!

        query = URI.encode_www_form(
          client_id: client_id,
          redirect_uri: redirect_uri,
          response_type: "code",
          scope: "openid email profile",
          state: state,
          code_challenge: code_challenge,
          code_challenge_method: "S256",
          access_type: "online",
          prompt: "select_account"
        )
        "#{AUTHORIZE_URL}?#{query}"
      end

      def fetch_profile(code:, code_verifier:, redirect_uri:)
        ensure_configured!

        token_data = http_post_form(
          TOKEN_URL,
          client_id: client_id,
          client_secret: client_secret,
          code: code,
          code_verifier: code_verifier,
          grant_type: "authorization_code",
          redirect_uri: redirect_uri
        )

        access_token = token_data["access_token"]
        raise ProviderError.new("Missing access token from Google", code: :oauth_failed) if access_token.blank?

        profile = http_get_json(
          USERINFO_URL,
          headers: { "Authorization" => "Bearer #{access_token}" }
        )

        uid = profile["sub"].to_s
        raise ProviderError.new("Missing Google user identifier", code: :oauth_failed) if uid.blank?

        {
          uid: uid,
          email: profile["email"]&.strip&.downcase.presence,
          email_verified: profile["email_verified"] == true,
          name: profile["name"]
        }
      end

      private

      def client_id
        fetch_credential("GOOGLE_CLIENT_ID", :google, :client_id)
      end

      def client_secret
        fetch_credential("GOOGLE_CLIENT_SECRET", :google, :client_secret)
      end

      def ensure_configured!
        return if client_id.present? && client_secret.present?

        raise ProviderError.new("Google OAuth is not configured", code: :oauth_not_configured)
      end
    end
  end
end
