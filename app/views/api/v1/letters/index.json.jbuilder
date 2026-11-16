# frozen_string_literal: true

json.data do
  json.array! @letters, partial: "api/v1/letters/letter", as: :letter
end
json.meta do
  json.partial! "api/v1/shared/pagination", pagy: @pagy
end
