# frozen_string_literal: true

module Letters
  class DestroyService
    def self.call(id_or_signed_id, current_user_email)
      new(id_or_signed_id, current_user_email).call
    end

    def initialize(id_or_signed_id, current_user_email)
      @id_or_signed_id = id_or_signed_id
      @current_user_email = current_user_email
    end

    def call
      letter = find_letter

      return Result.new(success: false, error: :not_found) if letter.nil?

      policy = LetterPolicy.new(@current_user_email, letter)
      return Result.new(success: false, error: :not_found) unless policy.destroy?

      return Result.new(success: false, error: :cannot_delete) unless letter.can_delete?

      letter_id = letter.id
      email = letter.email
      scheduled_at = letter.scheduled_at&.iso8601
      status_at_deletion = letter.status

      letter.destroy!

      AuditLog.record!(
        action: "letter.deleted",
        auditable: nil,
        actor_email: @current_user_email,
        metadata: {
          letter_id: letter_id,
          scheduled_at: scheduled_at,
          status_at_deletion: status_at_deletion
        }
      )

      Analytics::TrackEventService.call("letter_deleted", { letter_id: letter_id, email: email })

      Result.new(success: true, letter: letter)
    end

    private

    def find_letter
      Letter.find_signed(@id_or_signed_id.to_s) || Letter.find_by(id: @id_or_signed_id)
    end

    class Result
      attr_reader :letter, :error

      def initialize(success:, letter: nil, error: nil)
        @success = success
        @letter = letter
        @error = error
      end

      def success?
        @success
      end
    end
  end
end
