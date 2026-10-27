# frozen_string_literal: true

module Auth
  class DestroySessionService
    def self.call(email:, token: nil)
      new(email: email, token: token).call
    end

    def initialize(email:, token: nil)
      @email = email
      @token = token
    end

    def call
      if @token.present?
        session_token = SessionToken.active.find_by(token: @token)
        session_token&.use!
      end

      Analytics::TrackEventService.call("user_logged_out", { email: @email }) if @email.present?

      Result.new(success: true)
    end

    class Result
      def initialize(success:)
        @success = success
      end

      def success?
        @success
      end
    end
  end
end
