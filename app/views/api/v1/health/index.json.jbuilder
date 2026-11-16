# frozen_string_literal: true

json.data do
  json.status @health[:status]
  json.timestamp @health[:timestamp]
  json.version @health[:version]
  json.services @health[:services]
end
