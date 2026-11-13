# frozen_string_literal: true

module Api
  module V1
    class StampCategoriesController < BaseController
      def index
        @locale = I18n.locale
        categories_scope = StampCategory.active.with_active_stamps.ordered

        max_cat_updated = StampCategory.maximum(:updated_at)
        max_stamp_updated = Stamp.maximum(:updated_at)
        cat_count = categories_scope.count

        return unless stale?(etag: [ max_cat_updated, max_stamp_updated, cat_count, @locale ], public: true)

        @stamp_categories = categories_scope
      end
    end
  end
end
