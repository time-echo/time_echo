# frozen_string_literal: true

module Letters
  class DispatchPendingService
    def self.call
      new.call
    end

    def call
      letter_ids = []

      Letter.transaction do
        letters = PendingLettersQuery.call.to_a
        return 0 if letters.empty?

        letter_ids = letters.map(&:id)
        Rails.logger.info("Queuing #{letter_ids.size} pending letters for delivery")

        Letter.where(id: letter_ids).update_all(status: "queued", queued_at: Time.current)

        letters.each do |letter|
          AuditLog.record!(
            action: "letter.queued",
            auditable: letter,
            actor_email: letter.email,
            metadata: {
              from_status: "pending",
              to_status: "queued"
            }
          )
        end
      end

      jobs = letter_ids.map { |id| Letters::DeliverLetterJob.new(id) }
      ActiveJob.perform_all_later(jobs)

      Rails.logger.info("Delivery dispatch complete queued=#{letter_ids.size}")
      letter_ids.size
    end
  end
end
