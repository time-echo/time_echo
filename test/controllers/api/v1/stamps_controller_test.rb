# frozen_string_literal: true

require "test_helper"

class Api::V1::StampsControllerTest < ActionDispatch::IntegrationTest
  setup do
    Stamp.delete_all
    StampCategory.delete_all

    @cat1 = StampCategory.create!(
      slug: "small-things",
      name: { "en" => "Small Things", "es" => "Pequeñas cosas" },
      position: 1,
      active: true
    )
    @cat2 = StampCategory.create!(
      slug: "passage-of-time",
      name: { "en" => "Passage of Time", "es" => "El paso del tiempo" },
      position: 2,
      active: true
    )
    @inactive_cat = StampCategory.create!(
      slug: "inactive-category",
      name: { "en" => "Inactive Cat", "es" => "Categoría inactiva" },
      position: 3,
      active: false
    )
    @empty_cat = StampCategory.create!(
      slug: "empty-category",
      name: { "en" => "Empty", "es" => "Vacía" },
      position: 4,
      active: true
    )

    @stamp1 = Stamp.create!(
      stamp_category: @cat1,
      slug: "morning-coffee",
      name: { "en" => "Morning Coffee", "es" => "Café matutino" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><circle cx=\"24\" cy=\"24\" r=\"10\"/></svg>",
      position: 1,
      active: true
    )
    @stamp2 = Stamp.create!(
      stamp_category: @cat2,
      slug: "one-more-year",
      name: { "en" => "One More Year", "es" => "Un año más" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><rect width=\"20\" height=\"20\"/></svg>",
      position: 1,
      active: true
    )
    @inactive_stamp = Stamp.create!(
      stamp_category: @cat1,
      slug: "inactive-stamp",
      name: { "en" => "Inactive", "es" => "Inactivo" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 2,
      active: false
    )
    @inactive_cat_stamp = Stamp.create!(
      stamp_category: @inactive_cat,
      slug: "orphaned-stamp",
      name: { "en" => "Orphaned", "es" => "Huérfano" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: true
    )
  end

  test "GET /api/v1/stamps returns only active stamps of active categories ordered" do
    get "/api/v1/stamps?locale=es"
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("stamps")
    stamps = json["stamps"]

    assert_equal 2, stamps.length
    assert_equal "morning-coffee", stamps.first["slug"]
    assert_equal "Café matutino", stamps.first["name"]
    assert_equal "small-things", stamps.first["category_slug"]

    assert_equal "one-more-year", stamps.second["slug"]
    assert_equal "El paso del tiempo", @cat2.localized_name(:es)

    # Verify inactive and orphaned stamps are excluded
    slugs = stamps.map { |s| s["slug"] }
    assert_not_includes slugs, "inactive-stamp"
    assert_not_includes slugs, "orphaned-stamp"
  end

  test "GET /api/v1/stamps supports HTTP caching with ETag" do
    get "/api/v1/stamps?locale=en"
    assert_response :ok
    etag = response.headers["ETag"]
    assert etag.present?

    get "/api/v1/stamps?locale=en", headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end

  test "GET /api/v1/stamp_categories returns active categories with active stamps ordered" do
    get "/api/v1/stamp_categories?locale=es"
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("stamp_categories")
    categories = json["stamp_categories"]

    assert_equal 2, categories.length
    assert_equal "small-things", categories.first["slug"]
    assert_equal "Pequeñas cosas", categories.first["name"]
    assert_equal 1, categories.first["position"]

    assert_equal "passage-of-time", categories.second["slug"]

    # Verify inactive and empty categories are excluded
    cat_slugs = categories.map { |c| c["slug"] }
    assert_not_includes cat_slugs, "inactive-category"
    assert_not_includes cat_slugs, "empty-category"
  end

  test "GET /api/v1/stamp_categories supports HTTP caching with ETag" do
    get "/api/v1/stamp_categories?locale=en"
    assert_response :ok
    etag = response.headers["ETag"]
    assert etag.present?

    get "/api/v1/stamp_categories?locale=en", headers: { "If-None-Match" => etag }
    assert_response :not_modified
  end

  test "GET /api/v1/stamps/:slug returns historical stamp even if inactive" do
    get "/api/v1/stamps/#{@inactive_stamp.slug}?locale=es"
    assert_response :ok

    json = JSON.parse(response.body)
    assert json.key?("stamp")
    stamp_data = json["stamp"]

    assert_equal "inactive-stamp", stamp_data["slug"]
    assert_equal "Inactivo", stamp_data["name"]
    assert_equal "small-things", stamp_data["category_slug"]
    assert_equal "Pequeñas cosas", stamp_data["category_name"]
    assert_equal false, stamp_data["active"]
    assert stamp_data["svg_content"].present?
  end

  test "GET /api/v1/stamps/:slug returns 404 for nonexistent stamp" do
    get "/api/v1/stamps/nonexistent-stamp"
    assert_response :not_found
  end
end
