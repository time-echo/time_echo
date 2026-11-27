# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

json.inspiration do
  json.slug @inspiration.slug
  json.text @inspiration.localized_text(@locale)
  json.category_slug @inspiration.inspiration_category.slug
  json.categorySlug @inspiration.inspiration_category.slug
  json.category_name @inspiration.inspiration_category.localized_name(@locale)
  json.categoryName @inspiration.inspiration_category.localized_name(@locale)
  json.category_description @inspiration.inspiration_category.localized_description(@locale)
  json.categoryDescription @inspiration.inspiration_category.localized_description(@locale)
  json.position @inspiration.position
  json.active @inspiration.active
end
