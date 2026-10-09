require "ostruct"

module Settings
  class ConfirmEmailUpdateService
    def self.call(token)
      new(token).call
    end

    def initialize(token)
      @token = token
    end

    def call
      return OpenStruct.new(success?: false) if @token.blank?

      payload = Rails.application.message_verifier(:email_update).verified(@token)
      return OpenStruct.new(success?: false) unless payload.is_a?(Hash)

      old_email = payload[:old_email] || payload["old_email"]
      new_email = payload[:new_email] || payload["new_email"]

      return OpenStruct.new(success?: false) if old_email.blank? || new_email.blank?

      ActiveRecord::Base.transaction do
        Letter.where(email: old_email).update_all(email: new_email)
      end

      Analytics::TrackEventService.call("email_update_confirmed", { old_email: old_email, new_email: new_email }) rescue nil

      OpenStruct.new(success?: true, new_email: new_email)
    end
  end
end
