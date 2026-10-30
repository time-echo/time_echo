class Letter < ApplicationRecord
  include LetterStateMachine

  encrypts :title
  encrypts :content
  has_many :predictions, dependent: :destroy
  has_one :emotional_snapshot, dependent: :destroy

  normalizes :email, with: ->(email) { email.strip.downcase }

  alias_attribute :deliver_at, :scheduled_at

  STATUSES = %w[pending queued delivered failed archived].freeze

  attribute :language, :string, default: -> { I18n.locale.to_s }
  attribute :timezone, :string, default: -> { Time.zone&.name || "America/Bogota" }

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :content, presence: true
  validates :scheduled_at, presence: true
  validates :timezone, presence: true
  validates :status, inclusion: { in: STATUSES }
  validates :language, presence: true, inclusion: { in: I18n.available_locales.map(&:to_s) }
  validates :reveal_happiness, :reveal_anxiety, :reveal_motivation, numericality: { only_integer: true, in: 1..10 }, allow_nil: true

  validate :scheduled_at_must_be_in_future, on: :create
  validate :valid_iana_timezone

  scope :pending, -> { where(status: "pending").where("scheduled_at <= ?", Time.current) }
  scope :scheduled, -> { where(status: "pending").where("scheduled_at > ?", Time.current) }
  scope :delivered, -> { where(status: "delivered").order(delivered_at: :desc) }
  scope :active, -> { where.not(status: "archived") }
  scope :archived, -> { where(status: "archived").order(updated_at: :desc) }
  scope :for_email, ->(email) { where(email: email) }

  def pending?
    status == "pending"
  end

  def queued?
    status == "queued"
  end

  def delivered?
    status == "delivered"
  end

  def failed?
    status == "failed"
  end

  def archived?
    status == "archived"
  end

  def local_scheduled_at
    return nil unless scheduled_at
    tz = Time.find_zone(timezone) || Time.find_zone("UTC")
    scheduled_at.in_time_zone(tz)
  end

  def countdown_seconds
    return 0 if delivered? || archived?
    [ (scheduled_at - Time.current).to_i, 0 ].max
  end

  private

  def scheduled_at_must_be_in_future
    if scheduled_at.present? && scheduled_at <= Time.current
      errors.add(:scheduled_at, :must_be_in_future)
      errors.add(:deliver_at, :must_be_in_future) if errors[:deliver_at].empty?
    end
  end

  def valid_iana_timezone
    return if timezone.blank?
    unless Time.find_zone(timezone)
      errors.add(:timezone, :invalid_timezone)
    end
  end
end
