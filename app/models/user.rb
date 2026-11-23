# frozen_string_literal: true

require "digest"

class User < ApplicationRecord
  MIN_PASSWORD_LENGTH = 10
  MAX_PASSWORD_LENGTH = 72
  RESET_TOKEN_TTL = 1.hour

  has_secure_password validations: false

  has_many :identities, dependent: :destroy
  has_many :oauth_states, dependent: :destroy

  normalizes :email, with: ->(email) { email.to_s.strip.downcase }

  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }, uniqueness: { case_sensitive: false }
  validates :password, length: { minimum: MIN_PASSWORD_LENGTH, maximum: MAX_PASSWORD_LENGTH }, if: -> { password.present? }
  validates :password, confirmation: true, if: -> { password.present? && !password_confirmation.nil? }

  def self.digest_token(raw_token)
    Digest::SHA256.hexdigest(raw_token.to_s)
  end

  def self.find_by_reset_token(raw_token)
    return nil if raw_token.blank?

    user = find_by(reset_token_digest: digest_token(raw_token))
    user if user&.reset_token_valid?(raw_token)
  end

  def self.find_or_create_for_email!(email)
    normalized = email.to_s.strip.downcase
    find_by(email: normalized) || create!(email: normalized)
  rescue ActiveRecord::RecordNotUnique
    find_by!(email: normalized)
  end

  def has_password?
    password_digest.present?
  end

  def login_methods_count
    (has_password? ? 1 : 0) + identities.count
  end

  def generate_reset_token!
    raw_token = SecureRandom.urlsafe_base64(32)
    update!(
      reset_token_digest: self.class.digest_token(raw_token),
      reset_sent_at: Time.current
    )
    raw_token
  end

  def clear_reset_token!
    update!(reset_token_digest: nil, reset_sent_at: nil)
  end

  def reset_token_valid?(raw_token)
    return false if reset_token_digest.blank? || reset_sent_at.blank? || raw_token.blank?
    return false if reset_sent_at < RESET_TOKEN_TTL.ago

    ActiveSupport::SecurityUtils.secure_compare(reset_token_digest, self.class.digest_token(raw_token))
  end
end
