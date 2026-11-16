# frozen_string_literal: true

module Auth
  class MagicLinkService
    def self.generate_and_send(email, locale: nil)
      normalized_email = email.to_s.strip.downcase
      token_record = nil

      SessionToken.transaction do
        SessionToken.revoke_active_for(normalized_email)
        token_record = SessionToken.create!(email: normalized_email)
      end

      AuthMailer.magic_link(normalized_email, token_record.token, locale).deliver_later
      token_record
    end
  end
end
