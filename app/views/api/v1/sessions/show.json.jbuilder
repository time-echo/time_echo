# frozen_string_literal: true

json.data do
  json.email @session_data[:email]
  json.token @session_data[:token]
end
json.meta({})
