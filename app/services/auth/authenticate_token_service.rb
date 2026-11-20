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
        return ServiceResult.failure(
          :invalid_token,
          message: I18n.t("flash.invalid_link")
        )
      end

      email = token_record.email
      api_session_token = nil
      is_new_user = false

      SessionToken.transaction do
        is_new_user = !SessionToken.where(email: email).where.not(used_at: nil).exists? &&
                      !AuditLog.where(actor_email: email).exists?
        token_record.use!
        SessionToken.revoke_active_for(email)
        api_session_token = SessionToken.create!(email: email)
      end

      Analytics::TrackEventService.call("user_logged_in", { email: email })

      user_id = Analytics::UserIdentifier.for(email)
      auth_event = is_new_user ? "user_signed_up" : "user_logged_in"

      Analytics::PosthogService.identify(
        user_id: user_id,
        properties: {
          locale: I18n.locale.to_s
        }
      )
      Analytics::PosthogService.track(
        event: auth_event,
        user_id: user_id,
        properties: {
          auth_method: "magic_link",
          locale: I18n.locale.to_s
        }
      )

      ServiceResult.success(
        {
          user_id: user_id,
          email: email,
          token: api_session_token.token,
          is_new_user: is_new_user
        }
      )
    end

    Result = ServiceResult
  end
end
