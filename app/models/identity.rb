# frozen_string_literal: true

class Identity < ApplicationRecord
  PROVIDERS = %w[google facebook].freeze

  belongs_to :user

  normalizes :email, with: ->(email) { email.present? ? email.to_s.strip.downcase : nil }
  normalizes :provider, with: ->(provider) { provider.to_s.strip.downcase }

  validates :provider, presence: true, inclusion: { in: PROVIDERS }
  validates :uid, presence: true, uniqueness: { scope: :provider }
  validates :provider, uniqueness: { scope: :user_id }
end
