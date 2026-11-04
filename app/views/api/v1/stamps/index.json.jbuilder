# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

stamps_list = @stamps.map do |stamp|
  {
    slug: stamp.slug,
    name: stamp.localized_name(@locale),
    category_slug: stamp.stamp_category.slug,
    categorySlug: stamp.stamp_category.slug,
    position: stamp.position,
    svg_content: stamp.svg_content,
    svgContent: stamp.svg_content
  }
end

json.stamps stamps_list
