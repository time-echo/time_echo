# frozen_string_literal: true

class StampCategory < ApplicationRecord
  has_many :stamps, dependent: :restrict_with_error

  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :invalid }
  validates :name, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, id: :asc) }
  scope :with_active_stamps, -> {
    joins(:stamps).where(stamps: { active: true }).distinct
  }

  def localized_name(locale = I18n.locale)
    return "" unless name.is_a?(Hash)

    loc = locale.to_s
    name[loc].presence || name["en"].presence || name["es"].presence || name.values.find(&:present?) || ""
  end
end
