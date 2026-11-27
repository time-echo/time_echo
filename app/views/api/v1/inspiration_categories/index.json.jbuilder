# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

categories_list = @inspiration_categories.map do |category|
  {
    slug: category.slug,
    name: category.localized_name(@locale),
    description: category.localized_description(@locale),
    position: category.position
  }
end

json.inspiration_categories categories_list
json.inspirationCategories categories_list
