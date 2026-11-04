# frozen_string_literal: true

class Stamp < ApplicationRecord
  belongs_to :stamp_category
  has_many :letters, dependent: :restrict_with_error

  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :invalid }
  validates :name, presence: true
  validates :svg_content, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  validate :validate_svg_content

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, id: :asc) }
  scope :in_active_categories, -> {
    joins(:stamp_category).where(stamp_categories: { active: true })
  }

  def localized_name(locale = I18n.locale)
    return "" unless name.is_a?(Hash)

    loc = locale.to_s
    name[loc].presence || name["en"].presence || name["es"].presence || name.values.find(&:present?) || ""
  end

  private

  PROHIBITED_TAGS = %w[script foreignobject style iframe audio video object embed link].freeze

  def validate_svg_content
    return if svg_content.blank?

    trimmed = svg_content.strip

    unless trimmed.downcase.start_with?("<svg") && trimmed.downcase.end_with?("</svg>")
      errors.add(:svg_content, :invalid)
      return
    end

    PROHIBITED_TAGS.each do |tag|
      if trimmed.match?(%r{<\s*#{tag}\b}i)
        errors.add(:svg_content, :invalid)
        return
      end
    end

    if trimmed.match?(/\bon\w+\s*=/i)
      errors.add(:svg_content, :invalid)
      return
    end

    if trimmed.match?(/(?:href|src)\s*=\s*["']?\s*(?:javascript|data):/i)
      errors.add(:svg_content, :invalid)
      return
    end

    if trimmed.match?(/(?:href|src)\s*=\s*["']?\s*https?:\/\//i)
      errors.add(:svg_content, :invalid)
    end
  end
end
