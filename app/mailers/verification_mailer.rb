class VerificationMailer < ApplicationMailer
  def confirm_email(old_email, new_email, token)
    @old_email = old_email
    @new_email = new_email
    @confirm_url = confirm_email_update_url(token: token)

    mail(
      to: @new_email,
      subject: t("mailers.confirm_email.subject"),
      tags: [
        { name: "email_type", value: "confirm_email" }
      ]
    )
  end

  private

  def confirm_email_update_url(token:)
    Rails.application.routes.url_helpers.confirm_email_update_settings_url(token: token, host: ENV.fetch("APP_HOST") { "localhost:3000" })
  end
end
