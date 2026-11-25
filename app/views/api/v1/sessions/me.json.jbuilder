# frozen_string_literal: true

json.data do
  json.authenticated true
  json.user_id ::Analytics::UserIdentifier.for(@email)
  json.email @email
  json.has_password @user&.has_password? || false
  json.identities @identities.map { |identity| { provider: identity.provider, email: identity.email, linked_at: identity.created_at.iso8601 } }
  json.locale I18n.locale.to_s
end
json.meta({})
