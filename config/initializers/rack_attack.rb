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

  def self.parsed_json_body(req)
    return req.env["rack_attack.parsed_json_body"] if req.env.key?("rack_attack.parsed_json_body")

    body = if req.media_type == "application/json" && req.body
             raw = req.body.read
             req.body.rewind
             raw.present? ? JSON.parse(raw) : {}
    else
             {}
    end
    req.env["rack_attack.parsed_json_body"] = body.is_a?(Hash) ? body : {}
  rescue JSON::ParserError
    req.env["rack_attack.parsed_json_body"] = {}
  end

  def self.password_login_request?(req)
    return false unless req.path == "/api/v1/sessions" && req.post?

    body = parsed_json_body(req)
    password = body["password"] || body.dig("session", "password") || req.params["password"] || req.params.dig("session", "password")
    password.present?
  end

  def self.login_email_identifier(req)
    body = parsed_json_body(req)
    email = body["email"] || body.dig("session", "email") || req.params["email"] || req.params.dig("session", "email")
    email.to_s.strip.downcase.presence
  end

  # 2. Magic Link submission limit per IP
  # 5 requests per minute per IP to prevent spamming transactional emails
  throttle("logins/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/sessions" && req.post? && !password_login_request?(req)
  end

  # 2b. Password login limits: 10/min/ip and 5/min per email identifier
  throttle("password_logins/ip", limit: 10, period: 1.minute) do |req|
    req.ip if password_login_request?(req)
  end

  throttle("password_logins/email", limit: 5, period: 1.minute) do |req|
    login_email_identifier(req) if password_login_request?(req)
  end

  # 2c. Password reset requests per IP
  throttle("password_resets/ip", limit: 3, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/password_resets" && req.post?
  end

  # 2d. Account password update per IP
  throttle("account_password/ip", limit: 5, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/account/password" && (req.patch? || req.put?)
  end

  # 2e. OAuth endpoints per IP
  throttle("oauth_authorizations/ip", limit: 20, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/oauth_authorizations" && req.post?
  end

  throttle("oauth_callbacks/ip", limit: 10, period: 1.minute) do |req|
    req.ip if req.path == "/api/v1/oauth_callbacks" && req.post?
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
