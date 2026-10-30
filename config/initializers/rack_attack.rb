# frozen_string_literal: true

class Rack::Attack
  # Use memory store or Rails.cache for tracking limits
  Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new

  # Disable rate limiting in development environment
  Rack::Attack.enabled = false if Rails.env.development?

  ### Safelists ###
  # Always allow health checks everywhere
  safelist("allow-health-check") do |req|
    req.path == "/up" || req.path == "/livez" || req.path == "/readyz"
  end

  ### Throttles ###

  # 1. Global IP Throttle: Limit total requests per IP to mitigate volumetric DoS
  # 300 requests per minute per IP
  throttle("req/ip", limit: 300, period: 1.minute, &:ip)

  # 2. Login / Magic Link submission limit per IP
  # 5 requests per minute per IP to prevent spamming transactional emails
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/sessions" && req.post?
  end

  # 3. Letter submission limit per IP
  # 10 requests per minute per IP to prevent automated letter flooding
  throttle("letters/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/letters" && req.post?
  end

  # 4. Sensitive account destruction requests per IP
  # 3 requests per minute per IP
  throttle("account_deletion/ip", limit: 3, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/account" && req.delete?
  end

  ### Custom Blocked / Throttled Response ###
  self.throttled_responder = lambda do |req|
    match_data = req.env["rack.attack.match_data"] || {}
    now = match_data[:epoch_time] || Time.now.to_i
    period = match_data[:period] || 60
    retry_after = (period - (now % period)).to_s
    req_id = req.env["action_dispatch.request_id"] || req.env["HTTP_X_REQUEST_ID"]

    headers = {
      "Content-Type" => "application/json; charset=utf-8",
      "Retry-After" => retry_after
    }
    body = {
      error: {
        code: "rate_limited",
        message: "Too many requests. Please retry after #{retry_after} seconds.",
        requestId: req_id
      }
    }.to_json

    [ 429, headers, [ body ] ]
  end
end
