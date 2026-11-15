# frozen_string_literal: true

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
      unless valid_email?
        msg = I18n.t("settings.invalid_email")
        return Result.new(success: false, code: :invalid, error: msg, message: msg)
      end

      if @new_email == @old_email
        msg = I18n.t("settings.same_email")
        return Result.new(success: false, code: :same_email, error: msg, message: msg)
      end

      token = Rails.application.message_verifier(:email_update).generate(
        { old_email: @old_email, new_email: @new_email },
        expires_in: 15.minutes
      )

      VerificationMailer.confirm_email(@old_email, @new_email, token).deliver_later
      Analytics::TrackEventService.call("email_update_requested", { old_email: @old_email, new_email: @new_email })

      Result.new(
        success: true,
        value: {
          email: @new_email,
          message: I18n.t("settings.email_update_requested_message", email: @new_email)
        }
      )
    end

    private

    def valid_email?
      @new_email.present? && @new_email.match?(URI::MailTo::EMAIL_REGEXP)
    end

    class Result
      attr_reader :value, :code, :error, :message

      def initialize(success:, value: nil, code: nil, error: nil, message: nil)
        @success = success
        @value = value
        @code = code
        @error = error
        @message = message
      end

      def success?
        @success
      end
    end
  end
end
