# frozen_string_literal: true

json.data do
  json.partial! "api/v1/letters/letter", letter: @letter
end
json.meta({})
