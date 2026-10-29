# frozen_string_literal: true

module Accounts
  class RequestEmailUpdateService
    def self.call(new_email, old_email)
      new(new_email, old_email).call
    end

    def initialize(new_email, old_email)
      @new_email = new_email&.strip&.downcase
      @old_email = old_email&.strip&.downcase
    end

    def call
      unless valid_email?
        msg = I18n.t("settings.invalid_email", default: "Por favor introduce un correo electrónico válido.")
        return Result.new(success: false, error: :invalid, message: msg)
      end

      if @new_email == @old_email
        msg = I18n.t("settings.same_email", default: "El nuevo correo no puede ser igual al actual.")
        return Result.new(success: false, error: :same_email, message: msg)
      end

      token = Rails.application.message_verifier(:email_update).generate(
        { old_email: @old_email, new_email: @new_email },
        expires_in: 15.minutes
      )

      VerificationMailer.confirm_email(@old_email, @new_email, token).deliver_later
      Analytics::TrackEventService.call("email_update_requested", { old_email: @old_email, new_email: @new_email }) rescue nil

      Result.new(
        success: true,
        value: {
          email: @new_email,
          message: I18n.t("settings.email_update_requested_message", email: @new_email, default: "Se ha enviado un enlace de confirmación a #{@new_email}.")
        }
      )
    end

    private

    def valid_email?
      @new_email.present? && @new_email.match?(URI::MailTo::EMAIL_REGEXP)
    end

    class Result
      attr_reader :value, :error, :message

      def initialize(success:, value: nil, error: nil, message: nil)
        @success = success
        @value = value
        @error = error
        @message = message
      end

      def success?
        @success
      end
    end
  end
end
