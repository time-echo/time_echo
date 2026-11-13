# frozen_string_literal: true

require "test_helper"

class RackAttackTest < ActionDispatch::IntegrationTest
  setup do
    Rack::Attack.enabled = true
    Rack::Attack.reset!
  end

  teardown do
    Rack::Attack.reset!
    Rack::Attack.enabled = false
  end

  test "health check /up is safelisted and never throttled" do
    10.times do
      get "/up"
      assert_response :success
    end
  end

  test "throttles excessive login requests per IP after 5 attempts" do
    5.times do |i|
      post "/api/v1/sessions", params: { email: "attacker#{i}@example.com" }, as: :json
      assert_response :created
    end

    post "/api/v1/sessions", params: { email: "attacker_final@example.com" }, as: :json
    assert_response :too_many_requests
    assert_equal "application/json; charset=utf-8", response.headers["Content-Type"]
    assert response.headers["Retry-After"].present?
    json = JSON.parse(response.body)
    assert_equal "rate_limited", json["error"]["code"]
  end

  test "throttles excessive letter submissions per IP after 10 attempts" do
    params = {
      letter: {
        title: "Flood Letter",
        email: "flood@example.com",
        content: "Reflections from the past designed to test volumetric submission limits on letter form.",
        deliver_at: 1.year.from_now.to_s,
        timezone: "America/Bogota"
      }
    }

    10.times do |i|
      payload = params.deep_dup
      payload[:letter][:email] = "flood#{i}@example.com"
      post "/api/v1/letters", params: payload, as: :json
    end

    post "/api/v1/letters", params: params, as: :json
    assert_response :too_many_requests
    assert_equal "application/json; charset=utf-8", response.headers["Content-Type"]
    assert response.headers["Retry-After"].present?
  end

  test "throttles sensitive account deletion attempts after 3 tries" do
    3.times do
      delete "/api/v1/account", as: :json
    end

    delete "/api/v1/account", as: :json
    assert_response :too_many_requests
  end
end
