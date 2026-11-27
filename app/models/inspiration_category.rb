# frozen_string_literal: true

class InspirationCategory < ApplicationRecord
  has_many :inspirations, dependent: :restrict_with_error

  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :invalid }
  validates :name, presence: true
  validates :description, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, id: :asc) }
  scope :with_active_inspirations, -> {
    joins(:inspirations).where(inspirations: { active: true }).distinct
  }

  def localized_name(locale = I18n.locale)
    localized_field(name, locale)
  end

  def localized_description(locale = I18n.locale)
    localized_field(description, locale)
  end

  private

  def localized_field(hash, locale)
    return "" unless hash.is_a?(Hash)

    loc = locale.to_s
    hash[loc].presence || hash["en"].presence || hash["es"].presence || hash.values.find(&:present?) || ""
  end
end
