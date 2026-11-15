# frozen_string_literal: true

module Settings
  class DestroyAccountService
    def self.call(email)
      new(email).call
    end

    def initialize(email)
      @email = email
    end

    def call
      ActiveRecord::Base.transaction do
        letters = Letter.where(email: @email).to_a

        letters.each do |letter|
          AuditLog.record!(
            action: "letter.deleted",
            auditable: nil,
            actor_email: @email,
            metadata: {
              letter_id: letter.id,
              scheduled_at: letter.scheduled_at&.iso8601,
              status_at_deletion: letter.status
            }
          )
          letter.destroy!
        end

        SessionToken.where(email: @email).delete_all
        AnalyticsEvent.where("metadata ->> 'email' = ?", @email).delete_all
      end

      Result.new(success: true)
    end

    class Result
      def initialize(success:)
        @success = success
      end

      def success?
        @success
      end
    end
  end
end
