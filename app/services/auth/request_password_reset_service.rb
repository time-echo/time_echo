# frozen_string_literal: true

module Auth
  class RequestPasswordResetService
    MAX_RESETS_PER_HOUR = 5

    def self.call(email:, locale: nil)
      new(email: email, locale: locale).call
    end

    def initialize(email:, locale: nil)
      @raw_email = email
      @email = email.to_s.strip.downcase
      @locale = normalize_locale(locale) || normalize_locale(I18n.locale) || I18n.default_locale
    end

    def call
      I18n.with_locale(@locale) do
        unless @email.match?(URI::MailTo::EMAIL_REGEXP)
          user = User.new(email: @raw_email)
          user.errors.add(:email, :invalid)
          return ServiceResult.failure(:invalid, errors: user.errors)
        end

        user = User.find_by(email: @email)
        if user.present? && !hourly_limit_reached?(user.email)
          raw_token = user.generate_reset_token!
          AuditLog.record!(
            action: "account.password_reset_requested",
            actor_email: user.email
          )
          PasswordMailer.reset(user.email, raw_token, @locale).deliver_later
        end

        ServiceResult.success(
          {
            message: I18n.t("flash.password_reset_sent")
          }
        )
      end
    end

    Result = ServiceResult

    private

    def hourly_limit_reached?(email)
      AuditLog.where(action: "account.password_reset_requested", actor_email: email)
              .where("created_at >= ?", 1.hour.ago)
              .count >= MAX_RESETS_PER_HOUR
    end

    def normalize_locale(raw)
      return nil if raw.blank?

      code = raw.to_s.scan(/^[a-z]{2}/i).first&.downcase&.to_sym
      code if code && I18n.available_locales.include?(code)
    end
  end
end
