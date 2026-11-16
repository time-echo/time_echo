# frozen_string_literal: true

class PendingLettersQuery
  def self.call(relation = Letter.all, time: Time.current)
    new(relation, time: time).call
  end

  def initialize(relation = Letter.all, time: Time.current)
    @relation = relation
    @time = time
  end

  def call
    @relation
      .where(status: "pending")
      .where("scheduled_at <= ?", @time)
      .order(scheduled_at: :asc)
      .lock("FOR UPDATE SKIP LOCKED")
  end
end
