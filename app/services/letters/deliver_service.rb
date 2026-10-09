module Letters
  class DeliverService
    def self.call(letter)
      new(letter).call
    end

    def initialize(letter)
      @letter = letter
    end

    def call
      return if @letter.delivered? || @letter.archived?

      I18n.with_locale(@letter.language.presence || I18n.default_locale) do
        LetterMailer.future_letter(@letter).deliver_now
      end

      @letter.update!(status: "delivered", delivered_at: Time.current)

      AuditLog.record!(
        action: "letter.delivered",
        auditable: @letter,
        actor_email: @letter.email,
        metadata: {
          delivered_at: @letter.delivered_at&.iso8601,
          language: @letter.language
        }
      )

      Analytics::TrackEventService.call("email_delivered", {
        letter_id: @letter.id,
        email: @letter.email
      })
    end
  end
end
