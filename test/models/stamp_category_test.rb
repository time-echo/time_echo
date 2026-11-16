# frozen_string_literal: true

require "test_helper"

class StampCategoryTest < ActiveSupport::TestCase
  test "valid stamp category" do
    category = StampCategory.new(
      slug: "small-things",
      name: { "en" => "Small Things", "es" => "Pequeñas cosas" },
      position: 1,
      active: true
    )
    assert category.valid?
  end

  test "invalid without slug" do
    category = StampCategory.new(name: { "en" => "Small Things" }, position: 1)
    assert_not category.valid?
    assert category.errors[:slug].any?
  end

  test "invalid with malformed slug" do
    category = StampCategory.new(slug: "Small Things!", name: { "en" => "Small Things" }, position: 1)
    assert_not category.valid?
    assert category.errors[:slug].any?
  end

  test "invalid with duplicate slug" do
    StampCategory.create!(slug: "unique-category", name: { "en" => "Unique" }, position: 1)
    dup = StampCategory.new(slug: "unique-category", name: { "en" => "Duplicate" }, position: 2)
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "invalid without name" do
    category = StampCategory.new(slug: "small-things", position: 1)
    assert_not category.valid?
    assert category.errors[:name].any?
  end

  test "invalid without numeric position" do
    category = StampCategory.new(slug: "small-things", name: { "en" => "Small Things" }, position: -1)
    assert_not category.valid?
    assert category.errors[:position].any?
  end

  test "localized_name returns correct translation with fallback" do
    category = StampCategory.new(
      slug: "small-things",
      name: { "en" => "Small Things", "es" => "Pequeñas cosas" },
      position: 1
    )
    assert_equal "Pequeñas cosas", category.localized_name(:es)
    assert_equal "Small Things", category.localized_name(:en)
    assert_equal "Small Things", category.localized_name(:fr)
  end

  test "scopes filter active and order by position" do
    cat2 = StampCategory.create!(slug: "cat-2", name: { "en" => "Cat 2" }, position: 2, active: true)
    cat1 = StampCategory.create!(slug: "cat-1", name: { "en" => "Cat 1" }, position: 1, active: true)
    cat_inactive = StampCategory.create!(slug: "cat-3", name: { "en" => "Cat 3" }, position: 0, active: false)

    active_ordered = StampCategory.active.ordered
    assert_includes active_ordered, cat1
    assert_includes active_ordered, cat2
    assert_not_includes active_ordered, cat_inactive
    assert_operator active_ordered.index(cat1), :<, active_ordered.index(cat2)
  end

  test "cannot be destroyed if it has associated stamps" do
    category = StampCategory.create!(slug: "has-stamps", name: { "en" => "Category" }, position: 1)
    category.stamps.create!(
      slug: "associated-stamp",
      name: { "en" => "Stamp" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1
    )

    assert_no_difference "StampCategory.count" do
      assert_not category.destroy
    end
    assert category.errors[:base].any?
  end
end
