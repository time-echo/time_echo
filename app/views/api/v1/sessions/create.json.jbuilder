# frozen_string_literal: true

json.data do
  json.message @session_data[:message]
  json.email @session_data[:email]
end
json.meta({})
