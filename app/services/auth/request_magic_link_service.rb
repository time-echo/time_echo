# frozen_string_literal: true

module Auth
  class RequestMagicLinkService
    def self.call(email:, locale: nil)
      new(email: email, locale: locale).call
    end

    def initialize(email:, locale: nil)
      @raw_email = email
      @normalized_email = email.to_s.strip.downcase
      @locale = resolve_locale(locale)
    end

    def call
      I18n.with_locale(@locale) do
        form = MagicLinkForm.new(email: @raw_email)
        unless form.valid?
          if form.errors[:base].any? { |msg| msg == I18n.t("errors.messages.magic_link_rate_limit_exceeded") }
            return ServiceResult.failure(
              :rate_limited,
              message: I18n.t("errors.messages.magic_link_rate_limit_exceeded")
            )
          end

          return ServiceResult.failure(
            :invalid,
            errors: form.errors
          )
        end

        Auth::MagicLinkService.generate_and_send(@normalized_email, locale: @locale)
        Analytics::TrackEventService.call("magic_link_requested", { email: @normalized_email, locale: @locale })

        ServiceResult.success(
          {
            message: I18n.t("flash.magic_link_sent", default: "Magic link dispatched"),
            email: @normalized_email
          }
        )
      end
    end

    Result = ServiceResult

    private

    def resolve_locale(explicit_locale)
      code = normalize_locale(explicit_locale)
      return code if code

      # Fallback to user's most recent letter language if available
      user_last_lang = Letter.where(email: @normalized_email).order(created_at: :desc).pick(:language)
      last_code = normalize_locale(user_last_lang)
      return last_code if last_code

      normalize_locale(I18n.locale) || I18n.default_locale
    end

    def normalize_locale(raw)
      return nil if raw.blank?

      code = raw.to_s.scan(/^[a-z]{2}/i).first&.downcase&.to_sym
      code if code && I18n.available_locales.include?(code)
    end
  end
end
