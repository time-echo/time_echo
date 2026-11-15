# frozen_string_literal: true

module Letters
  class ArchiveService
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
      return Result.new(success: false, error: :not_found) unless policy.archive?

      return Result.new(success: false, error: :cannot_archive_delivered) unless letter.can_archive?

      from_status = letter.status
      letter.archive!

      AuditLog.record!(
        action: "letter.archived",
        auditable: letter,
        actor_email: @current_user_email,
        metadata: {
          from_status: from_status,
          to_status: "archived"
        }
      )

      Analytics::TrackEventService.call("letter_archived", { letter_id: letter.id, email: letter.email })

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
