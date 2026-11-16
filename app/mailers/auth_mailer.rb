class AuthMailer < ApplicationMailer
  def magic_link(email, token, locale = nil)
    @email = email
    @magic_link_url = magic_login_url(token: token)

    resolved_locale = locale.is_a?(Hash) ? locale[:locale] : locale
    target_locale = (resolved_locale.presence || I18n.locale.presence || I18n.default_locale).to_sym

    I18n.with_locale(target_locale) do
      mail(
        to: @email,
        subject: t("mailers.magic_link.subject"),
        tags: [
          { name: "email_type", value: "magic_link" }
        ]
      )
    end
  end

  private

  def magic_login_url(token:)
    "#{app_base_url}/login/#{token}"
  end
end
