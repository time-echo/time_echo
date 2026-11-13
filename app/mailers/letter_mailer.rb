class LetterMailer < ApplicationMailer
  def future_letter(letter)
    @letter = letter
    @letter_url = "#{app_base_url}/letters/#{@letter.signed_id}"
    locale = @letter.language.presence || I18n.default_locale

    headers["X-Letter-ID"] = @letter.id.to_s

    I18n.with_locale(locale) do
      mail(
        to: @letter.email,
        subject: t("mailers.future_letter.subject", date: I18n.l((@letter.created_at || Time.current).to_date, format: :long)),
        tags: [
          { name: "letter_id", value: @letter.id.to_s },
          { name: "email_type", value: "future_letter" }
        ]
      )
    end
  end

  def stamped_confirmation(letter)
    @letter = letter
    @time_echo_url = "#{app_base_url}/"
    locale = @letter.language.presence || I18n.default_locale

    headers["X-Letter-ID"] = @letter.id.to_s

    I18n.with_locale(locale) do
      mail(
        to: @letter.email,
        subject: t("mailers.stamped_confirmation.subject", title: @letter.title),
        tags: [
          { name: "letter_id", value: @letter.id.to_s },
          { name: "email_type", value: "stamped_confirmation" }
        ]
      )
    end
  end
end
