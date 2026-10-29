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
    5.times do
      post login_path, params: { magic_link_form: { email: "attacker@example.com" } }
      assert_response :redirect
    end

    post login_path, params: { magic_link_form: { email: "attacker@example.com" } }
    assert_response :too_many_requests
    assert_equal "text/plain; charset=utf-8", response.headers["Content-Type"]
    assert response.headers["Retry-After"].present?
    assert_includes response.body, "Too Many Requests"
  end

  test "throttles excessive letter submissions per IP after 10 attempts" do
    params = {
      letter_form: {
        title: "Flood Letter",
        email: "flood@example.com",
        content: "Reflections from the past designed to test volumetric submission limits on letter form.",
        deliver_at: 1.year.from_now.to_s,
        timezone: "America/Bogota"
      }
    }

    10.times do
      post letters_path, params: params
    end

    post letters_path, params: params
    assert_response :too_many_requests
    assert_equal "text/plain; charset=utf-8", response.headers["Content-Type"]
    assert response.headers["Retry-After"].present?
  end

  test "throttles sensitive account deletion attempts after 3 tries" do
    3.times do
      delete settings_path
    end

    delete settings_path
    assert_response :too_many_requests
  end

  test "allows requests to static assets without triggering rate limits" do
    get "/assets/application.css"
    # Even if 404/not found or success, should not be 429
    assert_not_equal 429, response.status
  end
end
