# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

inspirations_list = @inspirations.map do |inspiration|
  {
    slug: inspiration.slug,
    text: inspiration.localized_text(@locale),
    category_slug: inspiration.inspiration_category.slug,
    categorySlug: inspiration.inspiration_category.slug,
    position: inspiration.position,
    active: inspiration.active
  }
end

json.inspirations inspirations_list
json.data inspirations_list
if @pagy
  json.meta do
    json.partial! "api/v1/shared/pagination", pagy: @pagy
  end
end
