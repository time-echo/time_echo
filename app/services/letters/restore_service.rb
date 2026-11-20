# frozen_string_literal: true

module Letters
  class RestoreService
    def self.call(id_or_signed_id, current_user_email)
      new(id_or_signed_id, current_user_email).call
    end

    def initialize(id_or_signed_id, current_user_email)
      @id_or_signed_id = id_or_signed_id
      @current_user_email = current_user_email
    end

    def call
      letter = find_letter

      return ServiceResult.failure(:not_found) if letter.nil?

      policy = LetterPolicy.new(@current_user_email, letter)
      return ServiceResult.failure(:not_found) unless policy.restore?

      return ServiceResult.failure(:cannot_restore) unless letter.can_restore?

      from_status = letter.status
      letter.restore!

      AuditLog.record!(
        action: "letter.restored",
        auditable: letter,
        actor_email: @current_user_email,
        metadata: {
          from_status: from_status,
          to_status: letter.status
        }
      )

      Analytics::TrackEventService.call("letter_restored", { letter_id: letter.id, email: letter.email })

      ServiceResult.success(letter: letter)
    end

    private

    def find_letter
      Letter.find_signed(@id_or_signed_id.to_s) || Letter.find_by(id: @id_or_signed_id)
    end

    Result = ServiceResult
  end
end
