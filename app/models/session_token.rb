# frozen_string_literal: true

class SessionToken < ApplicationRecord
  normalizes :email, with: ->(email) { email.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :token, presence: true, uniqueness: true
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current).where(used_at: nil) }

  before_validation :generate_token, on: :create
  before_validation :set_expiration, on: :create

  def self.revoke_active_for(email)
    return 0 if email.blank?

    normalized = email.to_s.strip.downcase
    active.where(email: normalized).update_all(used_at: Time.current, updated_at: Time.current)
  end

  def expired?
    expires_at <= Time.current
  end

  def used?
    used_at.present?
  end

  def use!
    update!(used_at: Time.current)
  end

  def revoke!
    use!
  end

  private

  def generate_token
    self.token ||= SecureRandom.hex(24)
  end

  def set_expiration
    self.expires_at ||= 15.minutes.from_now
  end
end
