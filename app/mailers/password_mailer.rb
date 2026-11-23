# frozen_string_literal: true

class PasswordMailer < ApplicationMailer
  def reset(email, token, locale = nil)
    @email = email
    @reset_url = password_reset_url(token: token)

    resolved_locale = locale.is_a?(Hash) ? locale[:locale] : locale
    target_locale = (resolved_locale.presence || I18n.locale.presence || I18n.default_locale).to_sym

    I18n.with_locale(target_locale) do
      mail(
        to: @email,
        subject: t("mailers.password_reset.subject"),
        tags: [
          { name: "email_type", value: "password_reset" }
        ]
      )
    end
  end

  private

  def password_reset_url(token:)
    "#{app_base_url}/reset-password/#{token}"
  end
end
