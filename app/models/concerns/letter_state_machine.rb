# frozen_string_literal: true

module LetterStateMachine
  extend ActiveSupport::Concern

  TRANSITIONS = {
    "pending" => %w[queued delivered archived],
    "queued" => %w[delivered failed archived pending],
    "failed" => %w[queued archived pending],
    "archived" => %w[pending delivered],
    "delivered" => %w[archived]
  }.freeze

  class InvalidTransitionError < StandardError; end

  included do
    validate :validate_status_transition, on: :update, if: :will_save_change_to_status?
  end

  def can_transition_to?(target_status)
    target_status = target_status.to_s
    allowed = TRANSITIONS[status] || []
    allowed.include?(target_status)
  end

  def can_archive?
    can_transition_to?("archived")
  end

  def can_restore?
    archived? && (can_transition_to?("pending") || can_transition_to?("delivered"))
  end

  def can_deliver?
    can_transition_to?("delivered")
  end

  def can_queue?
    can_transition_to?("queued")
  end

  def can_delete?
    archived?
  end

  def archive!
    transition_to!("archived")
  end

  def restore!
    target = delivered_at.present? || (scheduled_at.present? && scheduled_at <= Time.current) ? "delivered" : "pending"
    transition_to!(target)
  end

  def deliver!(time = Time.current)
    unless can_deliver?
      raise InvalidTransitionError, "Cannot deliver letter ##{id} from '#{status}'"
    end

    update!(status: "delivered", delivered_at: time)
  end

  def transition_to!(target_status)
    target_status = target_status.to_s
    unless can_transition_to?(target_status)
      raise InvalidTransitionError, "Cannot transition letter ##{id} from '#{status}' to '#{target_status}'"
    end

    update!(status: target_status)
  end

  private

  def validate_status_transition
    old_status = status_was
    new_status = status
    return if old_status == new_status

    allowed = TRANSITIONS[old_status] || []
    unless allowed.include?(new_status)
      errors.add(:status, "cannot transition from '#{old_status}' to '#{new_status}'")
    end
  end
end
