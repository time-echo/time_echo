# frozen_string_literal: true

module Auth
  class AuthenticateTokenService
    def self.call(token:)
      new(token: token).call
    end

    def initialize(token:)
      @token = token.to_s.strip
    end

    def call
      token_record = SessionToken.active.find_by(token: @token)
      if token_record.nil?
        return Result.new(
          success: false,
          error: :invalid_token,
          message: I18n.t("flash.invalid_link")
        )
      end

      email = token_record.email
      api_session_token = nil

      SessionToken.transaction do
        token_record.use!
        SessionToken.revoke_active_for(email)
        api_session_token = SessionToken.create!(email: email)
      end

      Analytics::TrackEventService.call("user_logged_in", { email: email })

      Result.new(
        success: true,
        value: {
          email: email,
          token: api_session_token.token
        }
      )
    end

    class Result
      attr_reader :value, :error, :message

      def initialize(success:, value: nil, error: nil, message: nil)
        @success = success
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
