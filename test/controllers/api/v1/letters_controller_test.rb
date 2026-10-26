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
    assert_response :unauthorized
  end

  test "GET /api/v1/letters returns letters list for authenticated user" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    assert_response :created

    get "/api/v1/letters", headers: @auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_kind_of Array, json
    assert_equal 1, json.length
    assert_equal "Future Self Letter", json.first["title"]
    assert json.first["docket_number"].present?
    assert json.first["emotional_snapshot"].present?
    assert_equal 2, json.first["predictions"].length
  end

  test "POST /api/v1/letters creates letter with nested attributes" do
    assert_difference -> { Letter.count } => 1, -> { EmotionalSnapshot.count } => 1, -> { Prediction.count } => 2 do
      post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    end

    assert_response :created
    json = JSON.parse(response.body)
    assert_equal "Future Self Letter", json["title"]
    assert_equal @user_email, json["email"]
    assert_equal 8, json["emotional_snapshot"]["happiness_level"]
    assert_equal 2, json["predictions"].length
  end

  test "POST /api/v1/letters returns 422 for invalid parameters" do
    invalid_payload = { letter: { title: "", content: "Too short" } }
    post "/api/v1/letters", params: invalid_payload, headers: @auth_headers

    assert_response :unprocessable_entity
    json = JSON.parse(response.body)
    assert_equal "unprocessable_entity", json["error"]
  end

  test "GET /api/v1/letters/:id returns single letter" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["id"]

    get "/api/v1/letters/#{letter_id}", headers: @auth_headers
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal letter_id, json["id"]
    assert_equal "Future Self Letter", json["title"]
  end

  test "POST /api/v1/letters/:id/archive and restore" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["id"]

    post "/api/v1/letters/#{letter_id}/archive", headers: @auth_headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "archived", json["status"]

    post "/api/v1/letters/#{letter_id}/restore", headers: @auth_headers
    assert_response :success
    json = JSON.parse(response.body)
    assert_equal "pending", json["status"]
  end

  test "DELETE /api/v1/letters/:id only allows deleting archived letters" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["id"]

    delete "/api/v1/letters/#{letter_id}", headers: @auth_headers
    assert_response :unprocessable_entity

    post "/api/v1/letters/#{letter_id}/archive", headers: @auth_headers
    assert_response :success

    delete "/api/v1/letters/#{letter_id}", headers: @auth_headers
    assert_response :no_content

    assert_nil Letter.find_by(id: letter_id)
  end

  test "POST /api/v1/letters/:id/predictions updates reality ledger" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created_letter = JSON.parse(response.body)
    letter_id = created_letter["id"]
    prediction_id = created_letter["predictions"].first["id"]

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
    assert_response :success

    json = JSON.parse(response.body)
    assert_equal 9, json["reveal_happiness"]
    assert_equal true, json["is_wax_broken"]
    updated_pred = json["predictions"].find { |p| p["id"] == prediction_id }
    assert_equal "Moved to Madrid in September", updated_pred["reality"]
    assert_equal true, updated_pred["matched"]
    assert_equal "fulfilled", updated_pred["outcome"]
  end
end
