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

  test "GET /api/v1/letters?status=archived returns archived letters" do
    get "/api/v1/letters?status=archived", headers: @auth_headers
    json = assert_collection_response(expected_status: :ok)

    assert_kind_of Array, json["data"]
    assert_equal 0, json["data"].length
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

  test "POST /api/v1/letters creates letter with empty predictions_attributes array" do
    payload = @create_payload.deep_dup
    payload[:letter][:predictions_attributes] = []

    assert_difference -> { Letter.count } => 1, -> { EmotionalSnapshot.count } => 1, -> { Prediction.count } => 0 do
      post "/api/v1/letters", params: payload, headers: @auth_headers, as: :json
    end

    json = assert_resource_response(expected_status: :created)
    assert_equal [], json["data"]["predictions"]
  end

  test "POST /api/v1/letters returns 422 for invalid parameters with details" do
    invalid_payload = { letter: { title: "", content: "Too short" } }
    post "/api/v1/letters", params: invalid_payload, headers: @auth_headers.merge("X-Locale" => "es")

    json = assert_error_response(expected_status: :unprocessable_content, expected_code: "validation_failed")
    assert json["error"]["details"].present?
    assert_includes json["error"]["message"], "El título no puede estar en blanco"
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

  test "GET /api/v1/letters/:id returns 401 when unauthorized" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    created = assert_resource_response(expected_status: :created)
    letter_id = created["data"]["id"]

    get "/api/v1/letters/#{letter_id}"
    assert_error_response(expected_status: :unauthorized, expected_code: "unauthorized")
  end

  test "GET /api/v1/letters/:id returns 404 not_found when user does not own the letter" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["data"]["id"]

    other_token = SessionToken.create!(email: "other_user@example.com")
    get "/api/v1/letters/#{letter_id}", headers: { "X-Session-Token" => other_token.token }

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "DELETE /api/v1/letters/:id returns 404 not_found when letter does not belong to user" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["data"]["id"]

    other_token = SessionToken.create!(email: "other_user@example.com")
    delete "/api/v1/letters/#{letter_id}", headers: { "X-Session-Token" => other_token.token }

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "POST /api/v1/letters/:id/archive returns 404 not_found when letter does not belong to user" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    letter_id = JSON.parse(response.body)["data"]["id"]

    other_token = SessionToken.create!(email: "other_user@example.com")
    post "/api/v1/letters/#{letter_id}/archive", headers: { "X-Session-Token" => other_token.token }

    assert_error_response(expected_status: :not_found, expected_code: "not_found")
  end

  test "GET /api/v1/letters/:id returns 404 not_found when letter does not exist" do
    get "/api/v1/letters/99999999", headers: @auth_headers
    assert_error_response(expected_status: :not_found, expected_code: "not_found")
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
    assert_error_response(expected_status: :unprocessable_content, expected_code: "cannot_delete")

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

  test "POST /api/v1/letters creates letter without stamp when stamp_slug is absent" do
    post "/api/v1/letters", params: @create_payload, headers: @auth_headers
    json = assert_resource_response(expected_status: :created)

    assert_nil json["data"]["stamp"]
    created_letter = Letter.find(json["data"]["id"])
    assert_nil created_letter.stamp_id
  end

  test "POST /api/v1/letters creates letter with valid active stamp" do
    category = StampCategory.create!(slug: "travel", name: { "en" => "Travel", "es" => "Viajes" }, position: 1, active: true)
    stamp = Stamp.create!(
      stamp_category: category,
      slug: "vintage-plane",
      name: { "en" => "Vintage Plane", "es" => "Avión clásico" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: true
    )

    payload = @create_payload.deep_dup
    payload[:letter][:stamp_slug] = "vintage-plane"

    post "/api/v1/letters", params: payload, headers: @auth_headers
    json = assert_resource_response(expected_status: :created)

    stamp_data = json["data"]["stamp"]
    assert_not_nil stamp_data
    assert_equal "vintage-plane", stamp_data["slug"]
    assert_equal "Avión clásico", stamp_data["name"]
    assert_equal "travel", stamp_data["categorySlug"]

    created_letter = Letter.find(json["data"]["id"])
    assert_equal stamp.id, created_letter.stamp_id
  end

  test "POST /api/v1/letters creates letter when stampId or both stampId and stamp_slug are passed" do
    category = StampCategory.create!(slug: "postal", name: { "en" => "Postal", "es" => "Postal" }, position: 2, active: true)
    stamp = Stamp.create!(
      stamp_category: category,
      slug: "post-horn",
      name: { "en" => "Post Horn", "es" => "Corneta postal" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: true
    )

    payload = @create_payload.deep_dup
    payload[:letter][:stamp_slug] = "post-horn"
    payload[:letter][:stampId] = "post-horn"

    post "/api/v1/letters", params: payload, headers: @auth_headers
    json = assert_resource_response(expected_status: :created)
    assert_equal "post-horn", json["data"]["stamp"]["slug"]
  end

  test "POST /api/v1/letters rejects non-existent stamp_slug" do
    payload = @create_payload.deep_dup
    payload[:letter][:stamp_slug] = "non-existent-stamp"

    post "/api/v1/letters", params: payload, headers: @auth_headers
    assert_response :unprocessable_content

    json = JSON.parse(response.body)
    details = json.dig("error", "details") || json["errors"]
    assert (details["stamp_slug"] || details["stampSlug"]).present?
  end

  test "POST /api/v1/letters rejects inactive stamp_slug" do
    category = StampCategory.create!(slug: "nature", name: { "en" => "Nature", "es" => "Naturaleza" }, position: 1, active: true)
    Stamp.create!(
      stamp_category: category,
      slug: "inactive-leaf",
      name: { "en" => "Leaf", "es" => "Hoja" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: false
    )

    payload = @create_payload.deep_dup
    payload[:letter][:stamp_slug] = "inactive-leaf"

    post "/api/v1/letters", params: payload, headers: @auth_headers
    assert_response :unprocessable_content

    json = JSON.parse(response.body)
    details = json.dig("error", "details") || json["errors"]
    assert (details["stamp_slug"] || details["stampSlug"]).present?
  end

  test "POST /api/v1/letters rejects stamp in inactive category" do
    category = StampCategory.create!(slug: "archived-cat", name: { "en" => "Archived", "es" => "Archivado" }, position: 1, active: false)
    Stamp.create!(
      stamp_category: category,
      slug: "valid-stamp-in-inactive-cat",
      name: { "en" => "Stamp", "es" => "Estampilla" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: true
    )

    payload = @create_payload.deep_dup
    payload[:letter][:stamp_slug] = "valid-stamp-in-inactive-cat"

    post "/api/v1/letters", params: payload, headers: @auth_headers
    assert_response :unprocessable_content

    json = JSON.parse(response.body)
    details = json.dig("error", "details") || json["errors"]
    assert (details["stamp_slug"] || details["stampSlug"]).present?
  end
end
