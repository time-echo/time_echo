# frozen_string_literal: true

json.data do
  json.status "alive"
  json.timestamp Time.current.iso8601
end
json.meta({})
