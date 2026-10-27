# frozen_string_literal: true

json.data do
  json.authenticated true
  json.email @email
  json.locale I18n.locale.to_s
end
json.meta({})
