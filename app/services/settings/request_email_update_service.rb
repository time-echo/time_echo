require "ostruct"

module Settings
  class RequestEmailUpdateService
    def self.call(new_email, old_email)
      new(new_email, old_email).call
    end

    def initialize(new_email, old_email)
      @new_email = new_email&.strip&.downcase
      @old_email = old_email&.strip&.downcase
    end

    def call
      return OpenStruct.new(success?: false, error: I18n.t("settings.invalid_email", default: "Por favor introduce un correo electrónico válido.")) unless valid_email?
      return OpenStruct.new(success?: false, error: I18n.t("settings.same_email", default: "El nuevo correo no puede ser igual al actual.")) if @new_email == @old_email

      token = Rails.application.message_verifier(:email_update).generate(
        { old_email: @old_email, new_email: @new_email },
        expires_in: 15.minutes
      )

      VerificationMailer.confirm_email(@old_email, @new_email, token).deliver_later
      Analytics::TrackEventService.call("email_update_requested", { old_email: @old_email, new_email: @new_email }) rescue nil

      OpenStruct.new(success?: true)
    end

    private

    def valid_email?
      @new_email.present? && @new_email.match?(URI::MailTo::EMAIL_REGEXP)
    end
  end
end
