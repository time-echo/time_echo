# frozen_string_literal: true

module Letters
  class AccessService
    def self.call(id_or_signed_id, current_user_email, include_archived: false)
      new(id_or_signed_id, current_user_email, include_archived: include_archived).call
    end

    def initialize(id_or_signed_id, current_user_email, include_archived: false)
      @id_or_signed_id = id_or_signed_id
      @current_user_email = current_user_email
      @include_archived = include_archived
    end

    def call
      letter = find_letter

      if letter.nil? || (!@include_archived && letter.archived?)
        return ServiceResult.failure(:not_found)
      end

      policy = LetterPolicy.new(@current_user_email, letter)
      unless policy.show?
        return ServiceResult.failure(:not_found)
      end

      countdown = letter.pending?

      Analytics::PosthogService.track(
        event: "letter_viewed",
        email: @current_user_email.presence || letter.email,
        properties: {
          letter_id: letter.id.to_s,
          status: letter.status,
          is_locked: countdown,
          is_opened: letter.opened_at.present?
        }
      )

      ServiceResult.success(letter: letter, countdown: countdown)
    end

    private

    def find_letter
      Letter.find_signed(@id_or_signed_id.to_s) || Letter.find_by(id: @id_or_signed_id)
    end

    Result = ServiceResult
  end
end
