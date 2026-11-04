class LetterForm
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :title, :string
  attribute :email, :string
  attribute :content, :string
  attribute :scheduled_at
  attribute :timezone, :string, default: -> { Time.zone&.name || "America/Bogota" }
  attribute :language, :string, default: -> { I18n.locale.to_s }

  attribute :prediction_city, :string
  attribute :prediction_salary, :string
  attribute :prediction_relationship, :string
  attribute :prediction_career, :string
  attribute :prediction_achievement, :string
  attribute :prediction_happiness, :string

  attribute :happiness_level, :integer, default: 5
  attribute :anxiety_level, :integer, default: 5
  attribute :motivation_level, :integer, default: 5

  validates :title, presence: true, length: { minimum: 3, maximum: 100 }, content_structure: true
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :content, presence: true, length: { minimum: 80, maximum: 2000 }, content_structure: { min_words: 10 }
  validates :scheduled_at, presence: true
  validates :timezone, presence: true
  validate :scheduled_at_must_be_in_future
  validate :valid_iana_timezone
  validate :creation_limit_not_exceeded

  validates :happiness_level, presence: true, numericality: { only_integer: true, in: 1..10 }
  validates :anxiety_level, presence: true, numericality: { only_integer: true, in: 1..10 }
  validates :motivation_level, presence: true, numericality: { only_integer: true, in: 1..10 }

  attr_reader :letter

  def initialize(attributes = {})
    attrs = attributes ? attributes.to_h.with_indifferent_access : {}

    snap = attrs.delete(:emotional_snapshot_attributes)
    if snap.present?
      attrs[:happiness_level] ||= snap[:happiness_level]
      attrs[:anxiety_level] ||= snap[:anxiety_level]
      attrs[:motivation_level] ||= snap[:motivation_level]
    end

    preds = attrs.delete(:predictions_attributes)
    if preds.present?
      list = preds.is_a?(Hash) ? preds.values : Array(preds)
      list.each do |p|
        cat = p[:category].to_s
        attrs["prediction_#{cat}"] ||= p[:prediction] if Prediction::CATEGORIES.include?(cat)
      end
    end

    super(attrs)
  end

  def emotional_snapshot_attributes=(snap)
    return if snap.blank?

    self.happiness_level = snap[:happiness_level] if snap[:happiness_level].present?
    self.anxiety_level = snap[:anxiety_level] if snap[:anxiety_level].present?
    self.motivation_level = snap[:motivation_level] if snap[:motivation_level].present?
  end

  def predictions_attributes=(preds)
    return if preds.blank?

    list = preds.is_a?(Hash) ? preds.values : Array(preds)
    list.each do |p|
      cat = p[:category].to_s
      public_send("prediction_#{cat}=", p[:prediction]) if Prediction::CATEGORIES.include?(cat)
    end
  end

  def deliver_at
    scheduled_at
  end

  def deliver_at=(val)
    self.scheduled_at = val
  end

  def parsed_utc_scheduled_at
    val = scheduled_at
    return nil if val.blank?
    return val.utc if val.is_a?(Time) || val.is_a?(ActiveSupport::TimeWithZone)

    tz = Time.find_zone(timezone) || Time.find_zone("UTC")
    if val.is_a?(Date)
      tz.local(val.year, val.month, val.day).utc
    elsif val.is_a?(String)
      parsed = tz.parse(val) rescue nil
      parsed&.utc
    else
      nil
    end
  end

  def save
    return false unless valid?

    utc_time = parsed_utc_scheduled_at

    Letter.transaction do
      @letter = Letter.new(
        title: title,
        email: email,
        content: content,
        scheduled_at: utc_time,
        timezone: timezone.presence || "UTC",
        language: language.presence || I18n.locale.to_s,
        status: "pending"
      )

      @letter.build_emotional_snapshot(
        happiness_level: happiness_level,
        anxiety_level: anxiety_level,
        motivation_level: motivation_level
      )

      build_prediction("city", prediction_city)
      build_prediction("salary", prediction_salary)
      build_prediction("relationship", prediction_relationship)
      build_prediction("career", prediction_career)
      build_prediction("achievement", prediction_achievement)
      build_prediction("happiness", prediction_happiness)

      @letter.save!

      Analytics::TrackEventService.call("letter_created", { email: email })
      Analytics::TrackEventService.call("emotional_snapshot_completed", { email: email })
      if any_predictions?
        Analytics::TrackEventService.call("predictions_completed", { email: email })
      end

      true
    end
  rescue ActiveRecord::RecordInvalid => e
    errors.add(:base, e.message)
    false
  end

  private

  def build_prediction(category, text)
    return if text.blank?
    @letter.predictions.build(category: category, prediction: text)
  end

  def any_predictions?
    [ prediction_city, prediction_salary, prediction_relationship, prediction_career, prediction_achievement ].any?(&:present?)
  end

  def scheduled_at_must_be_in_future
    utc_val = parsed_utc_scheduled_at
    if utc_val.blank?
      errors.add(:scheduled_at, :invalid)
    elsif utc_val <= Time.current
      errors.add(:scheduled_at, :must_be_in_future)
      errors.add(:deliver_at, :must_be_in_future)
    end
  end

  def valid_iana_timezone
    return if timezone.blank?
    unless Time.find_zone(timezone)
      errors.add(:timezone, :invalid_timezone)
    end
  end

  def creation_limit_not_exceeded
    return if Rails.env.development?
    return if email.blank?
    normalized_email = email.strip.downcase
    if Letter.for_email(normalized_email).where("created_at >= ?", 24.hours.ago).count >= 5
      errors.add(:base, I18n.t("errors.messages.letter_rate_limit_exceeded"))
    end
  end
end
