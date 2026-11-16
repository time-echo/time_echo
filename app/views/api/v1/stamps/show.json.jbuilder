# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

json.stamp do
  json.slug @stamp.slug
  json.name @stamp.localized_name(@locale)
  json.category_slug @stamp.stamp_category.slug
  json.categorySlug @stamp.stamp_category.slug
  json.category_name @stamp.stamp_category.localized_name(@locale)
  json.categoryName @stamp.stamp_category.localized_name(@locale)
  json.active @stamp.active
  json.svg_content @stamp.svg_content
  json.svgContent @stamp.svg_content
end
