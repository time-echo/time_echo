# frozen_string_literal: true

json.key_format! ->(key) { key.to_s }

json.inspiration do
  json.slug @inspiration.slug
  json.text @inspiration.localized_text(@locale)
  json.position @inspiration.position
  json.active @inspiration.active
end
