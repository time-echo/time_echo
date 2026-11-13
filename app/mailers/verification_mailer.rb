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
    "#{app_base_url}/settings/confirm_email?token=#{CGI.escape(token.to_s)}"
  end
end
