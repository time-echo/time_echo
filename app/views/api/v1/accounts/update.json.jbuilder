# frozen_string_literal: true

json.data do
  json.message @account_data[:message]
  json.email @account_data[:email]
end
json.meta({})
