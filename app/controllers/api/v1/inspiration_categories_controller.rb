# frozen_string_literal: true

module Api
  module V1
    class InspirationCategoriesController < BaseController
      def index
        @locale = I18n.locale
        categories_scope = InspirationCategory.active.with_active_inspirations.ordered

        max_cat_updated = InspirationCategory.maximum(:updated_at)
        max_inspiration_updated = Inspiration.maximum(:updated_at)
        cat_count = categories_scope.count

        return unless stale?(etag: [ max_cat_updated, max_inspiration_updated, cat_count, @locale ], public: true)

        @inspiration_categories = categories_scope
      end
    end
  end
end
