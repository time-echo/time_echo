# frozen_string_literal: true

require "test_helper"

class Api::V1::AuthFlowsControllerTest < ActionDispatch::IntegrationTest
  test "POST /api/v1/registrations creates account and POST /api/v1/sessions logs in with password" do
    post "/api/v1/registrations",
      params: { email: "pw_flow@example.com", password: "secure-password-123", password_confirmation: "secure-password-123" },
      as: :json

    reg_json = assert_resource_response(expected_status: :created)
    assert_equal "pw_flow@example.com", reg_json["data"]["email"]
    assert reg_json["data"]["token"].present?
    assert_equal true, reg_json["data"]["is_new_user"]

    post "/api/v1/sessions",
      params: { email: "pw_flow@example.com", password: "wrong-password-123" },
      as: :json
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")

    post "/api/v1/sessions",
      params: { email: "pw_flow@example.com", password: "secure-password-123" },
      as: :json
    login_json = assert_resource_response(expected_status: :created)
    assert_equal "pw_flow@example.com", login_json["data"]["email"]
    assert login_json["data"]["token"].present?
  end

  test "POST and PATCH /api/v1/password_resets complete full reset flow" do
    user = User.create!(email: "ctrl_reset@example.com", password: "initial-password-123")

    assert_enqueued_emails 1 do
      post "/api/v1/password_resets", params: { email: user.email }, as: :json
    end
    known_json = assert_resource_response(expected_status: :ok)

    assert_no_enqueued_emails do
      post "/api/v1/password_resets", params: { email: "ghost_user@example.com" }, as: :json
    end
    unknown_json = assert_resource_response(expected_status: :ok)
    assert_equal known_json["data"]["message"], unknown_json["data"]["message"]

    raw_token = user.generate_reset_token!
    patch "/api/v1/password_resets/#{raw_token}",
      params: { password: "new-reset-password-456", password_confirmation: "new-reset-password-456" },
      as: :json
    assert_resource_response(expected_status: :ok)
    assert user.reload.authenticate("new-reset-password-456")
  end

  test "PATCH /api/v1/account/password updates password when authenticated" do
    user = User.create!(email: "ctrl_settings@example.com", password: "old-password-123")
    current_token = SessionToken.create!(email: user.email)
    other_token = SessionToken.create!(email: user.email)

    patch "/api/v1/account/password",
      params: { current_password: "wrong-password", password: "new-password-456" },
      headers: { "Authorization" => "Bearer #{current_token.token}" },
      as: :json
    assert_error_response(expected_status: :unprocessable_content, expected_code: "invalid_current_password")

    patch "/api/v1/account/password",
      params: { current_password: "old-password-123", password: "new-password-456", password_confirmation: "new-password-456" },
      headers: { "Authorization" => "Bearer #{current_token.token}" },
      as: :json
    assert_resource_response(expected_status: :ok)
    assert user.reload.authenticate("new-password-456")
    assert_not current_token.reload.used?
    assert other_token.reload.used?
  end

  test "GET /api/v1/account/identities and DELETE /api/v1/account/identities/:provider" do
    user = User.create!(email: "ctrl_oauth@example.com", password: "account-password-123")
    user.identities.create!(provider: "google", uid: "g-ctrl-1", email: user.email)
    token = SessionToken.create!(email: user.email)

    get "/api/v1/account/identities",
      headers: { "Authorization" => "Bearer #{token.token}" },
      as: :json
    idx_json = assert_resource_response(expected_status: :ok)
    assert_equal true, idx_json["data"]["has_password"]
    assert_equal true, idx_json["data"]["can_unlink"]
    assert_equal "google", idx_json["data"]["identities"].first["provider"]

    delete "/api/v1/account/identities/google",
      headers: { "Authorization" => "Bearer #{token.token}" },
      as: :json
    assert_resource_response(expected_status: :ok)
    assert_not user.identities.exists?(provider: "google")
  end
end
