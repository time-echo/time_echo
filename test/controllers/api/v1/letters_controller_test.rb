# frozen_string_literal: true

require "test_helper"

class Api::V1::LettersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user_email = "api_user@example.com"
    @token_record = SessionToken.create!(email: @user_email)
    @auth_headers = { "X-Session-Token" => @token_record.token }

    @create_payload = {
      letter: {
        title: "Future Self Letter",
        email: @user_email,
        content: "Writing this letter to reflect on where I am today and where I hope to be one year from now.",
        scheduled_at: 1.year.from_now.iso8601,
        language: "es",
        timezone: "America/Bogota",
        emotional_snapshot_attributes: {
          happiness_level: 8,
          anxiety_level: 2,
          motivation_level: 9
        },
        predictions_attributes: [
          { category: "city", prediction: "Living in Madrid" },
          { category: "career", prediction: "Working as Senior Lead" }
        ]
      }
    }
  end

  test "GET /api/v1/letters returns 401 when unauthorized" do
    get "/api/v1/letters"
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "GET /api/v1/letters returns letters list with pagination envelope for authenticated user" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    assert_resource_response(expected_status: :created)

    get "/api/v1/letters", headers: @auth_headers
    json = assert_collection_response(expected_status: :ok)

    assert_equal 1, json["data"].length
    first_letter = json["data"].first
    assert_equal "Future Self Letter", first_letter["title"]
    assert first_letter["docketNumber"].present?
    assert first_letter["emotionalSnapshot"].present?
    assert_equal 2, first_letter["predictions"].length

    assert_equal 1, json["meta"]["page"]
    assert_equal 20, json["meta"]["perPage"]
    assert_equal 1, json["meta"]["total"]
    assert_equal 1, json["meta"]["totalPages"]
  end

  test "POST /api/v1/letters creates letter with nested attributes and returns resource envelope" do
    assert_difference -> { Letter.count } => 1, -> { EmotionalSnapshot.count } => 1, -> { Prediction.count } => 2 do
      post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    end

    json = assert_resource_response(expected_status: :created)
    letter_data = json["data"]
    assert_equal "Future Self Letter", letter_data["title"]
    assert_equal @user_email, letter_data["email"]
    assert_equal 8, letter_data["emotionalSnapshot"]["happinessLevel"]
    assert_equal 2, letter_data["predictions"].length
  end

  test "POST /api/v1/letters returns 422 for invalid parameters with details" do
    invalid_payload = { letter: { title: "", content: "Too short" } }
    post "/api/v1/letters", params: invalid_payload, headers: @auth_headers

    json = assert_error_response(expected_status: :unprocessable_entity, expected_code: "validation_failed")
    assert json["error"]["details"].present?
  end

  test "GET /api/v1/letters/:id returns single letter in resource envelope" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created = assert_resource_response(expected_status: :created)
    letter_id = created["data"]["id"]

    get "/api/v1/letters/#{letter_id}", headers: @auth_headers
    json = assert_resource_response(expected_status: :ok)
    assert_equal letter_id, json["data"]["id"]
    assert_equal "Future Self Letter", json["data"]["title"]
  end

  test "POST /api/v1/letters/:id/archive and restore" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created = assert_resource_response(expected_status: :created)
    letter_id = created["data"]["id"]

    post "/api/v1/letters/#{letter_id}/archive", headers: @auth_headers
    archived_json = assert_resource_response(expected_status: :ok)
    assert_equal "archived", archived_json["data"]["status"]

    post "/api/v1/letters/#{letter_id}/restore", headers: @auth_headers
    restored_json = assert_resource_response(expected_status: :ok)
    assert_equal "pending", restored_json["data"]["status"]
  end

  test "DELETE /api/v1/letters/:id only allows deleting archived letters" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created = assert_resource_response(expected_status: :created)
    letter_id = created["data"]["id"]

    delete "/api/v1/letters/#{letter_id}", headers: @auth_headers
    assert_error_response(expected_status: :unprocessable_entity, expected_code: "cannot_delete")

    post "/api/v1/letters/#{letter_id}/archive", headers: @auth_headers
    assert_resource_response(expected_status: :ok)

    delete "/api/v1/letters/#{letter_id}", headers: @auth_headers
    assert_response :no_content

    assert_nil Letter.find_by(id: letter_id)
  end

  test "POST /api/v1/letters/:id/predictions updates reality ledger" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created = assert_resource_response(expected_status: :created)
    letter_id = created["data"]["id"]
    prediction_id = created["data"]["predictions"].first["id"]

    letter = Letter.find(letter_id)
    letter.update_columns(status: "delivered", delivered_at: Time.current)

    update_payload = {
      reveal_happiness: 9,
      reveal_anxiety: 1,
      reveal_motivation: 10,
      is_wax_broken: true,
      predictions: [
        { id: prediction_id, reality: "Moved to Madrid in September", matched: true }
      ]
    }

    post "/api/v1/letters/#{letter_id}/predictions", params: update_payload, headers: @auth_headers
    json = assert_resource_response(expected_status: :ok)

    letter_data = json["data"]
    assert_equal 9, letter_data["revealHappiness"]
    assert_equal true, letter_data["isWaxBroken"]
    updated_pred = letter_data["predictions"].find { |p| p["id"] == prediction_id }
    assert_equal "Moved to Madrid in September", updated_pred["reality"]
    assert_equal true, updated_pred["matched"]
    assert_equal "fulfilled", updated_pred["outcome"]
  end
end
