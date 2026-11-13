# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

categories_list = @stamp_categories.map do |category|
  {
    slug: category.slug,
    name: category.localized_name(@locale),
    position: category.position
  }
end

json.stamp_categories categories_list
json.stampCategories categories_list
