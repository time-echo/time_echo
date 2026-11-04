# frozen_string_literal: true

require "test_helper"

class StampTest < ActiveSupport::TestCase
  def setup
    @category = StampCategory.create!(
      slug: "test-category",
      name: { "en" => "Test Category", "es" => "Categoría de prueba" },
      position: 1,
      active: true
    )
  end

  test "valid stamp" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "morning-coffee",
      name: { "en" => "Morning Coffee", "es" => "Café matutino" },
      svg_content: "<svg xmlns=\"http://www.w3.org/2000/svg\" viewBox=\"0 0 48 48\"><ellipse cx=\"23\" cy=\"40\" rx=\"17\" ry=\"3.5\"/></svg>",
      position: 1,
      active: true
    )
    assert stamp.valid?
  end

  test "invalid without stamp_category" do
    stamp = Stamp.new(
      slug: "morning-coffee",
      name: { "en" => "Morning Coffee" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:stamp_category].any?
  end

  test "invalid without slug" do
    stamp = Stamp.new(
      stamp_category: @category,
      name: { "en" => "Morning Coffee" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:slug].any?
  end

  test "invalid with malformed slug" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "Morning Coffee!",
      name: { "en" => "Morning Coffee" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:slug].any?
  end

  test "invalid with duplicate slug" do
    Stamp.create!(
      stamp_category: @category,
      slug: "unique-stamp",
      name: { "en" => "Unique" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><circle cx=\"24\" cy=\"24\" r=\"10\"/></svg>",
      position: 1
    )
    dup = Stamp.new(
      stamp_category: @category,
      slug: "unique-stamp",
      name: { "en" => "Duplicate" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><circle cx=\"24\" cy=\"24\" r=\"10\"/></svg>",
      position: 2
    )
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "invalid without svg_content" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "morning-coffee",
      name: { "en" => "Morning Coffee" },
      svg_content: "",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "rejects svg with script tag" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "malicious-script",
      name: { "en" => "Script" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><script>alert('xss')</script></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "rejects svg with foreignObject tag" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "malicious-fo",
      name: { "en" => "Foreign Object" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><foreignObject><body><div>bad</div></body></foreignObject></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "rejects svg with event handlers" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "malicious-event",
      name: { "en" => "Onload Event" },
      svg_content: "<svg viewBox=\"0 0 48 48\" onload=\"alert(1)\"><rect width=\"10\" height=\"10\"/></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "rejects svg with javascript URI" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "malicious-js",
      name: { "en" => "JS URI" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><a href=\"javascript:alert(1)\"><circle r=\"5\"/></a></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "rejects svg with external href URL" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "malicious-external",
      name: { "en" => "External URL" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><image href=\"https://evil.com/img.png\"/></svg>",
      position: 1
    )
    assert_not stamp.valid?
    assert stamp.errors[:svg_content].any?
  end

  test "localized_name returns correct translation with fallback" do
    stamp = Stamp.new(
      stamp_category: @category,
      slug: "morning-coffee",
      name: { "en" => "Morning Coffee", "es" => "Café matutino" },
      position: 1
    )
    assert_equal "Café matutino", stamp.localized_name(:es)
    assert_equal "Morning Coffee", stamp.localized_name(:en)
    assert_equal "Morning Coffee", stamp.localized_name(:pt)
  end

  test "in_active_categories filters stamps whose category is inactive" do
    inactive_cat = StampCategory.create!(
      slug: "inactive-category",
      name: { "en" => "Inactive" },
      position: 2,
      active: false
    )
    active_stamp = Stamp.create!(
      stamp_category: @category,
      slug: "active-stamp",
      name: { "en" => "Active" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1,
      active: true
    )
    inactive_cat_stamp = Stamp.create!(
      stamp_category: inactive_cat,
      slug: "orphaned-stamp",
      name: { "en" => "Orphaned" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 2,
      active: true
    )

    filtered = Stamp.active.in_active_categories
    assert_includes filtered, active_stamp
    assert_not_includes filtered, inactive_cat_stamp
  end

  test "cannot be destroyed if associated with a letter" do
    stamp = Stamp.create!(
      stamp_category: @category,
      slug: "used-stamp",
      name: { "en" => "Used" },
      svg_content: "<svg viewBox=\"0 0 48 48\"><path d=\"M0 0\"/></svg>",
      position: 1
    )

    Letter.create!(
      title: "Letter with stamp",
      email: "author@example.com",
      content: "A letter content that is long enough to satisfy validations.",
      scheduled_at: 1.year.from_now,
      timezone: "America/Bogota",
      status: "pending",
      stamp: stamp
    )

    assert_no_difference "Stamp.count" do
      assert_not stamp.destroy
    end
    assert stamp.errors[:base].any?
  end
end
