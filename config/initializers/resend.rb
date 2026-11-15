# frozen_string_literal: true

begin
  resend_api_key = ENV["RESEND_API_KEY"].presence || Rails.application.credentials.dig(:resend_api_key)
rescue ActiveSupport::EncryptedFile::MissingKeyError
  resend_api_key = ENV["RESEND_API_KEY"].presence
end

if resend_api_key.present?
  Resend.api_key = resend_api_key
end
