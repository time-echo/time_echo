# frozen_string_literal: true

class Inspiration < ApplicationRecord
  belongs_to :inspiration_category

  validates :slug, presence: true,
                   uniqueness: { case_sensitive: false },
                   format: { with: /\A[a-z0-9]+(?:-[a-z0-9]+)*\z/, message: :invalid }
  validates :text, presence: true
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :active, inclusion: { in: [ true, false ] }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(position: :asc, id: :asc) }
  scope :in_active_categories, -> {
    joins(:inspiration_category).where(inspiration_categories: { active: true })
  }

  scope :by_category, ->(category_param) {
    return all if category_param.blank?

    if category_param.to_s.match?(/\A\d+\z/)
      where(inspiration_category_id: category_param)
    else
      joins(:inspiration_category).where(inspiration_categories: { slug: category_param.to_s.downcase })
    end
  }

  scope :search_by_text, ->(query) {
    return all if query.blank?

    pattern = "%#{sanitize_sql_like(query.to_s.strip)}%"
    where(
      "inspirations.slug ILIKE :term OR inspirations.text->>'en' ILIKE :term OR inspirations.text->>'es' ILIKE :term OR CAST(inspirations.text AS text) ILIKE :term",
      term: pattern
    )
  }

  scope :filter_by_status, ->(status_or_active) {
    return all if status_or_active.blank? || status_or_active.to_s.downcase == "all"

    is_active = ActiveRecord::Type::Boolean.new.cast(status_or_active)
    where(active: is_active)
  }

  def localized_text(locale = I18n.locale)
    return "" unless text.is_a?(Hash)

    loc = locale.to_s
    text[loc].presence || text["en"].presence || text["es"].presence || text.values.find(&:present?) || ""
  end
end
