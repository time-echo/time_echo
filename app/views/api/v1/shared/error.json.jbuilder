# frozen_string_literal: true

json.error do
  json.code @error_code
  json.message @error_message
  json.details @error_details if @error_details.present?
  json.request_id @request_id || request.request_id
end
