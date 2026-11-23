# frozen_string_literal: true

module Auth
  class IssueSessionService
    def self.call(user:, auth_method:, is_new_user: false)
      new(user: user, auth_method: auth_method, is_new_user: is_new_user).call
    end

    def initialize(user:, auth_method:, is_new_user: false)
      @user = user
      @auth_method = auth_method
      @is_new_user = is_new_user
    end

    def call
      api_session_token = SessionToken.create!(email: @user.email)

      AuditLog.record!(
        action: @is_new_user ? "account.registered" : "account.logged_in",
        actor_email: @user.email,
        metadata: { auth_method: @auth_method }
      )

      Analytics::TrackEventService.call("user_logged_in", { email: @user.email, auth_method: @auth_method })

      user_id = Analytics::UserIdentifier.for(@user.email)
      auth_event = @is_new_user ? "user_signed_up" : "user_logged_in"

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
          auth_method: @auth_method,
          locale: I18n.locale.to_s
        }
      )

      ServiceResult.success(
        {
          user_id: user_id,
          email: @user.email,
          token: api_session_token.token,
          is_new_user: @is_new_user
        }
      )
    end

    Result = ServiceResult
  end
end
