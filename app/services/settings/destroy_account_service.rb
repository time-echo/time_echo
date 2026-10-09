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
        letters = Letter.where(email: @email)
        letter_ids = letters.pluck(:id)

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
        end

        if letter_ids.any?
          conn = ActiveRecord::Base.connection
          %w[goals predictions emotional_snapshots].each do |table|
            conn.execute(conn.sanitize_sql_array([ "DELETE FROM #{table} WHERE letter_id IN (?)", letter_ids ])) rescue nil
          end
        end

        letters.destroy_all
        AnalyticsEvent.where("metadata ->> 'email' = ?", @email).delete_all rescue nil
      end
      true
    end
  end
end
