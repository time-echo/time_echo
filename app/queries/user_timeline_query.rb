# frozen_string_literal: true

class UserTimelineQuery
  def self.call(email, relation = Letter.all, status: nil)
    new(email, relation, status: status).call
  end

  def initialize(email, relation = Letter.all, status: nil)
    @email = email
    @relation = relation
    @status = status
  end

  def call
    if @status.to_s == "archived"
      @relation.archived.for_email(@email)
    else
      @relation.active.for_email(@email).order(deliver_at: :asc)
    end
  end
end
