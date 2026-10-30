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
        return Result.new(success: false, error: :not_found)
      end

      policy = LetterPolicy.new(@current_user_email, letter)
      unless policy.show?
        return Result.new(success: false, error: :not_found)
      end

      countdown = letter.pending?

      unless countdown
        if letter.opened_at.nil?
          letter.update!(opened_at: Time.current)
          Analytics::TrackEventService.call("letter_opened", { letter_id: letter.id, email: letter.email })
        end
      end

      Result.new(success: true, letter: letter, countdown: countdown)
    end

    private

    def find_letter
      Letter.find_signed(@id_or_signed_id.to_s) || Letter.find_by(id: @id_or_signed_id)
    end

    class Result
      attr_reader :letter, :error, :countdown
      def initialize(success:, letter: nil, error: nil, countdown: false)
        @success = success
        @letter = letter
        @error = error
        @countdown = countdown
      end

      def success?
        @success
      end

      def countdown?
        @countdown
      end
    end
  end
end
