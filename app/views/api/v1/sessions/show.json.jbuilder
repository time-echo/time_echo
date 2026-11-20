# frozen_string_literal: true

json.data do
  json.user_id @session_data[:user_id]
  json.email @session_data[:email]
  json.token @session_data[:token]
  json.is_new_user @session_data[:is_new_user]
end
json.meta({})
