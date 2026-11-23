class CleanupExpiredTokensJob < ApplicationJob
  queue_as :default

  def perform
    deleted_count = SessionToken.where("expires_at <= ?", Time.current)
                                .or(SessionToken.where.not(used_at: nil))
                                .delete_all
    deleted_oauth_states = OauthState.where("expires_at <= ?", Time.current).delete_all

    Rails.logger.info("Cleaned up #{deleted_count} expired tokens and #{deleted_oauth_states} expired oauth states")

    Analytics::TrackEventService.call("cleanup_expired_tokens", {
      deleted_count: deleted_count,
      deleted_oauth_states: deleted_oauth_states,
      occurred_at: Time.current
    })
  end
end
