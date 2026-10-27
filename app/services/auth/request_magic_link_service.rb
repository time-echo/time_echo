# frozen_string_literal: true

module Auth
  class RequestMagicLinkService
    def self.call(email:)
      new(email: email).call
    end

    def initialize(email:)
      @raw_email = email
      @normalized_email = email.to_s.strip.downcase
    end

    def call
      form = MagicLinkForm.new(email: @raw_email)
      unless form.valid?
        if form.errors[:base].any? { |msg| msg == I18n.t("errors.messages.magic_link_rate_limit_exceeded") }
          return Result.new(
            success: false,
            error: :rate_limited,
            message: I18n.t("errors.messages.magic_link_rate_limit_exceeded")
          )
        end

        return Result.new(
          success: false,
          error: :invalid,
          errors: form.errors
        )
      end

      Auth::MagicLinkService.generate_and_send(@normalized_email)
      Analytics::TrackEventService.call("magic_link_requested", { email: @normalized_email })

      Result.new(
        success: true,
        value: {
          message: I18n.t("flash.magic_link_sent", default: "Magic link dispatched"),
          email: @normalized_email
        }
      )
    end

    class Result
      attr_reader :value, :error, :errors, :message

      def initialize(success:, value: nil, error: nil, errors: nil, message: nil)
        @success = success
        @value = value
        @error = error
        @errors = errors
        @message = message
      end

      def success?
        @success
      end
    end
  end
end
