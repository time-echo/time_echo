# frozen_string_literal: true

require "test_helper"

class InspirationCategoryTest < ActiveSupport::TestCase
  test "valid inspiration category" do
    category = InspirationCategory.new(
      slug: "future-reflections",
      name: { "en" => "Future Reflections", "es" => "Reflexiones del futuro" },
      description: { "en" => "Thoughts about your future.", "es" => "Pensamientos sobre tu futuro." },
      position: 1,
      active: true
    )
    assert category.valid?
  end

  test "invalid without slug" do
    category = InspirationCategory.new(
      name: { "en" => "Future Reflections" },
      description: { "en" => "Thoughts" },
      position: 1
    )
    assert_not category.valid?
    assert category.errors[:slug].any?
  end

  test "invalid with malformed slug" do
    category = InspirationCategory.new(
      slug: "Future Reflections!",
      name: { "en" => "Future Reflections" },
      description: { "en" => "Thoughts" },
      position: 1
    )
    assert_not category.valid?
    assert category.errors[:slug].any?
  end

  test "invalid with duplicate slug" do
    InspirationCategory.create!(
      slug: "unique-inspiration-category",
      name: { "en" => "Unique" },
      description: { "en" => "Desc" },
      position: 1
    )
    dup = InspirationCategory.new(
      slug: "unique-inspiration-category",
      name: { "en" => "Duplicate" },
      description: { "en" => "Desc" },
      position: 2
    )
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "invalid without name or description" do
    category = InspirationCategory.new(slug: "future-reflections", position: 1)
    assert_not category.valid?
    assert category.errors[:name].any?
    assert category.errors[:description].any?
  end

  test "invalid with negative position" do
    category = InspirationCategory.new(
      slug: "future-reflections",
      name: { "en" => "Future" },
      description: { "en" => "Desc" },
      position: -1
    )
    assert_not category.valid?
    assert category.errors[:position].any?
  end

  test "localized_name and localized_description return correct translation with fallback" do
    category = InspirationCategory.new(
      slug: "future-reflections",
      name: { "en" => "Future Reflections", "es" => "Reflexiones del futuro" },
      description: { "en" => "English desc", "es" => "Descripción en español" },
      position: 1
    )
    assert_equal "Reflexiones del futuro", category.localized_name(:es)
    assert_equal "Future Reflections", category.localized_name(:en)
    assert_equal "Future Reflections", category.localized_name(:fr)

    assert_equal "Descripción en español", category.localized_description(:es)
    assert_equal "English desc", category.localized_description(:en)
    assert_equal "English desc", category.localized_description(:fr)
  end

  test "scopes filter active and order by position" do
    cat2 = InspirationCategory.create!(slug: "insp-cat-2", name: { "en" => "Cat 2" }, description: { "en" => "D2" }, position: 2, active: true)
    cat1 = InspirationCategory.create!(slug: "insp-cat-1", name: { "en" => "Cat 1" }, description: { "en" => "D1" }, position: 1, active: true)
    cat_inactive = InspirationCategory.create!(slug: "insp-cat-3", name: { "en" => "Cat 3" }, description: { "en" => "D3" }, position: 0, active: false)

    active_ordered = InspirationCategory.active.ordered
    assert_includes active_ordered, cat1
    assert_includes active_ordered, cat2
    assert_not_includes active_ordered, cat_inactive
    assert_operator active_ordered.index(cat1), :<, active_ordered.index(cat2)
  end

  test "cannot be destroyed if it has associated inspirations" do
    category = InspirationCategory.create!(
      slug: "has-inspirations",
      name: { "en" => "Category" },
      description: { "en" => "Desc" },
      position: 1
    )
    category.inspirations.create!(
      slug: "associated-inspiration",
      text: { "en" => "A prompt" },
      position: 1
    )

    assert_no_difference "InspirationCategory.count" do
      assert_not category.destroy
    end
    assert category.errors[:base].any?
  end
end
