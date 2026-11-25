# frozen_string_literal: true

require "base64"
require "digest"

class OauthState < ApplicationRecord
  TTL = 10.minutes
  PURPOSES = %w[login link].freeze

  belongs_to :user, optional: true

  validates :state_digest, presence: true, uniqueness: true
  validates :provider, presence: true, inclusion: { in: Identity::PROVIDERS }
  validates :code_verifier, presence: true
  validates :purpose, presence: true, inclusion: { in: PURPOSES }
  validates :expires_at, presence: true

  scope :active, -> { where("expires_at > ?", Time.current) }

  def self.digest(raw_state)
    Digest::SHA256.hexdigest(raw_state.to_s)
  end

  def self.create_for!(provider:, purpose: "login", user: nil)
    raw_state = SecureRandom.urlsafe_base64(32)
    record = create!(
      state_digest: digest(raw_state),
      provider: provider.to_s.strip.downcase,
      code_verifier: SecureRandom.urlsafe_base64(48),
      purpose: purpose,
      user: user,
      expires_at: TTL.from_now
    )
    [ raw_state, record ]
  end

  def self.consume!(raw_state:, provider:)
    return nil if raw_state.blank?

    normalized_provider = provider.to_s.strip.downcase
    candidate_digest = digest(raw_state)

    transaction do
      record = active.lock.find_by(state_digest: candidate_digest)
      return nil if record.nil?
      return nil unless ActiveSupport::SecurityUtils.secure_compare(record.state_digest, candidate_digest)
      return nil unless record.provider == normalized_provider

      record.destroy!
      record
    end
  end

  def code_challenge
    Base64.urlsafe_encode64(Digest::SHA256.digest(code_verifier), padding: false)
  end
end
