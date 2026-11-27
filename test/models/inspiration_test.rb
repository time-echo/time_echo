# frozen_string_literal: true

require "test_helper"

class InspirationTest < ActiveSupport::TestCase
  test "valid inspiration" do
    inspiration = Inspiration.new(
      slug: "person-to-become",
      text: { "en" => "Who do you hope to become?", "es" => "¿Quién esperas llegar a ser?" },
      position: 1,
      active: true
    )
    assert inspiration.valid?
  end

  test "invalid without slug" do
    inspiration = Inspiration.new(
      text: { "en" => "Who do you hope to become?" },
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:slug].any?
  end

  test "invalid with malformed slug" do
    inspiration = Inspiration.new(
      slug: "Person To Become!",
      text: { "en" => "Who do you hope to become?" },
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:slug].any?
  end

  test "invalid with duplicate slug" do
    Inspiration.create!(
      slug: "unique-inspiration",
      text: { "en" => "Unique" },
      position: 1
    )
    dup = Inspiration.new(
      slug: "unique-inspiration",
      text: { "en" => "Duplicate" },
      position: 2
    )
    assert_not dup.valid?
    assert dup.errors[:slug].any?
  end

  test "invalid without text" do
    inspiration = Inspiration.new(
      slug: "missing-text",
      position: 1
    )
    assert_not inspiration.valid?
    assert inspiration.errors[:text].any?
  end

  test "localized_text returns correct translation with fallback" do
    inspiration = Inspiration.new(
      slug: "person-to-become",
      text: { "en" => "Who do you hope to become?", "es" => "¿Quién esperas llegar a ser?" },
      position: 1
    )
    assert_equal "¿Quién esperas llegar a ser?", inspiration.localized_text(:es)
    assert_equal "Who do you hope to become?", inspiration.localized_text(:en)
    assert_equal "Who do you hope to become?", inspiration.localized_text(:pt)
  end
end
