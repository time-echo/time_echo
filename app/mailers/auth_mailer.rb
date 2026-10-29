class AuthMailer < ApplicationMailer
  def magic_link(email, token)
    @email = email
    @magic_link_url = magic_login_url(token: token)

    mail(
      to: @email,
      subject: t("mailers.magic_link.subject"),
      tags: [
        { name: "email_type", value: "magic_link" }
      ]
    )
  end

  private

  def magic_login_url(token:)
    base_url = ENV.fetch("FRONTEND_URL") { "http://#{ENV.fetch('APP_HOST', 'localhost:3000')}" }.chomp("/")
    "#{base_url}/login/#{token}"
  end
end
