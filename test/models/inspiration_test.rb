# frozen_string_literal: true

require "test_helper"

class InspirationTest < ActiveSupport::TestCase
  def setup
    @category = InspirationCategory.create!(
      slug: "test-insp-category",
      name: { "en" => "Test Category", "es" => "Categoría de prueba" },
      description: { "en" => "Test desc", "es" => "Descripción de prueba" },
      position: 1,
      active: true
    )
  end

  test "valid inspiration" do
    inspiration = Inspiration.new(
      inspiration_category: @category,
      slug: "person-to-become",
      text: { "en" => "Who do you hope to become?", "es" => "¿Quién esperas llegar a ser?" },
      position: 1,
      active: true
    )
    assert inspiration.valid?
  end

  test "invalid without inspiration_category" do
    inspiration = Inspiration.new(
      slug: "person-to-become",
      text: { "en" => "Who do you hope to become?" },
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:inspiration_category].any?
  end

  test "invalid without slug" do
    inspiration = Inspiration.new(
      inspiration_category: @category,
      text: { "en" => "Who do you hope to become?" },
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:slug].any?
  end

  test "invalid with malformed slug" do
    inspiration = Inspiration.new(
      inspiration_category: @category,
      slug: "Person To Become!",
      text: { "en" => "Who do you hope to become?" },
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:slug].any?
  end

  test "invalid with duplicate slug" do
    Inspiration.create!(
      inspiration_category: @category,
      slug: "unique-inspiration",
      text: { "en" => "Unique" },
      position: 1
    )
    dup = Inspiration.new(
      inspiration_category: @category,
      slug: "unique-inspiration",
      text: { "en" => "Duplicate" },
      position: 2
    )
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "invalid without text" do
    inspiration = Inspiration.new(
      inspiration_category: @category,
      slug: "missing-text",
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:text].any?
  end

  test "localized_text returns correct translation with fallback" do
    inspiration = Inspiration.new(
      inspiration_category: @category,
      slug: "person-to-become",
      text: { "en" => "Who do you hope to become?", "es" => "¿Quién esperas llegar a ser?" },
      position: 1
    )
    assert_equal "¿Quién esperas llegar a ser?", inspiration.localized_text(:es)
    assert_equal "Who do you hope to become?", inspiration.localized_text(:en)
    assert_equal "Who do you hope to become?", inspiration.localized_text(:pt)
  end

  test "in_active_categories filters inspirations whose category is inactive" do
    inactive_cat = InspirationCategory.create!(
      slug: "inactive-insp-category",
      name: { "en" => "Inactive" },
      description: { "en" => "Inactive desc" },
      position: 2,
      active: false
    )
    active_inspiration = Inspiration.create!(
      inspiration_category: @category,
      slug: "active-inspiration",
      text: { "en" => "Active prompt" },
      position: 1,
      active: true
    )
    inactive_cat_inspiration = Inspiration.create!(
      inspiration_category: inactive_cat,
      slug: "orphaned-inspiration",
      text: { "en" => "Orphaned prompt" },
      position: 2,
      active: true
    )

    filtered = Inspiration.active.in_active_categories
    assert_includes filtered, active_inspiration
    assert_not_includes filtered, inactive_cat_inspiration
  end
end
