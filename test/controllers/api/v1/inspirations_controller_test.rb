# frozen_string_literal: true

require "test_helper"

class Api::V1::InspirationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Inspiration.delete_all
    InspirationCategory.delete_all

    @cat1 = InspirationCategory.create!(
      slug: "future-reflections",
      name: { "en" => "Future Reflections", "es" => "Reflexiones del futuro" },
      description: { "en" => "Thoughts about your future.", "es" => "Pensamientos sobre tu futuro." },
      position: 1,
      active: true
    )
    @cat2 = InspirationCategory.create!(
      slug: "gratitude",
      name: { "en" => "Gratitude", "es" => "Gratitud" },
      description: { "en" => "Things you appreciate.", "es" => "Cosas que agradeces." },
      position: 2,
      active: true
    )
    @inactive_cat = InspirationCategory.create!(
      slug: "inactive-category",
      name: { "en" => "Inactive Cat", "es" => "Categoría inactiva" },
      description: { "en" => "Inactive desc", "es" => "Desc inactiva" },
      position: 3,
      active: false
    )
    @empty_cat = InspirationCategory.create!(
      slug: "empty-category",
      name: { "en" => "Empty", "es" => "Vacía" },
      description: { "en" => "Empty desc", "es" => "Desc vacía" },
      position: 4,
      active: true
    )

    @insp1 = Inspiration.create!(
      inspiration_category: @cat1,
      slug: "person-to-become",
      text: { "en" => "What kind of person do you hope to become?", "es" => "¿Qué tipo de persona esperas llegar a ser?" },
      position: 1,
      active: true
    )
    @insp2 = Inspiration.create!(
      inspiration_category: @cat2,
      slug: "moment-never-forget",
      text: { "en" => "What moment do you never want to forget?", "es" => "¿Qué momento no quieres olvidar nunca?" },
      position: 1,
      active: true
    )
    @inactive_insp = Inspiration.create!(
      inspiration_category: @cat1,
      slug: "inactive-inspiration",
      text: { "en" => "Inactive prompt", "es" => "Idea inactiva" },
      position: 2,
      active: false
    )
    @inactive_cat_insp = Inspiration.create!(
      inspiration_category: @inactive_cat,
      slug: "orphaned-inspiration",
      text: { "en" => "Orphaned prompt", "es" => "Idea huérfana" },
      position: 1,
      active: true
    )
  end

  test "GET /api/v1/inspirations returns only active inspirations of active categories ordered" do
    get "/api/v1/inspirations", params: { locale: "es" }
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("inspirations")
    inspirations = json["inspirations"]

    assert_equal 2, inspirations.length
    assert_equal "person-to-become", inspirations.first["slug"]
    assert_equal "¿Qué tipo de persona esperas llegar a ser?", inspirations.first["text"]
    assert_equal "future-reflections", inspirations.first["category_slug"]

    assert_equal "moment-never-forget", inspirations.second["slug"]
    assert_equal "gratitude", inspirations.second["category_slug"]

    slugs = inspirations.map { |i| i["slug"] }
    assert_not_includes slugs, "inactive-inspiration"
    assert_not_includes slugs, "orphaned-inspiration"
  end

  test "GET /api/v1/inspirations filters by text (English and Spanish)" do
    get "/api/v1/inspirations", params: { q: "person" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["inspirations"].length
    assert_equal "person-to-become", json["inspirations"].first["slug"]

    get "/api/v1/inspirations", params: { q: "olvidar" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["inspirations"].length
    assert_equal "moment-never-forget", json["inspirations"].first["slug"]
  end

  test "GET /api/v1/inspirations filters by category slug and category_id" do
    get "/api/v1/inspirations", params: { category: "gratitude" }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["inspirations"].length
    assert_equal "moment-never-forget", json["inspirations"].first["slug"]

    get "/api/v1/inspirations", params: { category_id: @cat1.id }
    assert_response :ok
    json = JSON.parse(response.body)
    assert_equal 1, json["inspirations"].length
    assert_equal "person-to-become", json["inspirations"].first["slug"]
  end

  test "GET /api/v1/inspirations filters by activation status" do
    get "/api/v1/inspirations", params: { active: "false" }
    assert_response :ok
    json = JSON.parse(response.body)
    slugs = json["inspirations"].map { |i| i["slug"] }
    assert_includes slugs, "inactive-inspiration"
    assert_not_includes slugs, "person-to-become"

    get "/api/v1/inspirations", params: { active: "all" }
    assert_response :ok
    json = JSON.parse(response.body)
    all_slugs = json["inspirations"].map { |i| i["slug"] }
    assert_includes all_slugs, "person-to-become"
    assert_includes all_slugs, "inactive-inspiration"
  end

  test "GET /api/v1/inspirations supports pagination" do
    get "/api/v1/inspirations", params: { page: 1, per_page: 1 }
    assert_response :ok
    json = JSON.parse(response.body)

    assert_equal 1, json["inspirations"].length
    assert json.key?("meta")
    meta = json["meta"]
    assert_equal 1, meta["page"]
    assert_equal 1, meta["per_page"]
    assert_equal 2, meta["total"]
    assert_equal 2, meta["total_pages"]

    get "/api/v1/inspirations", params: { page: 2, per_page: 1 }
    assert_response :ok
    json2 = JSON.parse(response.body)
    assert_equal 1, json2["inspirations"].length
    assert_equal 2, json2["meta"]["page"]
  end

  test "GET /api/v1/inspirations supports HTTP caching with ETag" do
    get "/api/v1/inspirations", params: { locale: "en" }
    assert_response :ok
    etag = response.headers["ETag"]
    assert etag.present?

    get "/api/v1/inspirations", params: { locale: "en" }, headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end

  test "GET /api/v1/inspiration_categories returns active categories with active inspirations ordered" do
    get "/api/v1/inspiration_categories", params: { locale: "es" }
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("inspiration_categories")
    categories = json["inspiration_categories"]

    assert_equal 2, categories.length
    assert_equal "future-reflections", categories.first["slug"]
    assert_equal "Reflexiones del futuro", categories.first["name"]
    assert_equal "Pensamientos sobre tu futuro.", categories.first["description"]
    assert_equal 1, categories.first["position"]

    assert_equal "gratitude", categories.second["slug"]

    cat_slugs = categories.map { |c| c["slug"] }
    assert_not_includes cat_slugs, "inactive-category"
    assert_not_includes cat_slugs, "empty-category"
  end

  test "GET /api/v1/inspiration_categories supports HTTP caching with ETag" do
    get "/api/v1/inspiration_categories", params: { locale: "en" }
    assert_response :ok
    etag = response.headers["ETag"]
    assert etag.present?

    get "/api/v1/inspiration_categories", params: { locale: "en" }, headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end

  test "GET /api/v1/inspirations/:slug returns inspiration even if inactive" do
    get "/api/v1/inspirations/#{@inactive_insp.slug}", params: { locale: "es" }
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("inspiration")
    data = json["inspiration"]

    assert_equal "inactive-inspiration", data["slug"]
    assert_equal "Idea inactiva", data["text"]
    assert_equal "future-reflections", data["category_slug"]
    assert_equal "Reflexiones del futuro", data["category_name"]
    assert_equal false, data["active"]
  end

  test "GET /api/v1/inspirations/:slug returns 404 for nonexistent inspiration" do
    get "/api/v1/inspirations/nonexistent-inspiration"
    assert_response :not_found
  end
end
