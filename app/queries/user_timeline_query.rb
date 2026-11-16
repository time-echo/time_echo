# frozen_string_literal: true

class UserTimelineQuery
  def self.call(email, relation = Letter.all, status: nil)
    new(email, relation, status: status).call
  end

  def initialize(email, relation = Letter.all, status: nil)
    @email = email
    @relation = relation
    @status = status.to_s.downcase.presence
  end

  def call
    base = @relation.for_email(@email)

    case @status
    when "archived"
      base.archived
    when "delivered"
      base.delivered
    when "scheduled"
      base.scheduled.order(scheduled_at: :asc)
    when "pending"
      base.where(status: "pending").order(scheduled_at: :asc)
    when "draft"
      base.where(status: "draft").order(updated_at: :desc)
    else
      base.active.order(scheduled_at: :asc)
    end
  end
end
