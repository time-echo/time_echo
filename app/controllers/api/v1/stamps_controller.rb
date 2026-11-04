# frozen_string_literal: true

module Api
  module V1
    class StampsController < BaseController
      def index
        @locale = I18n.locale
        stamps_scope = Stamp.active.in_active_categories
                            .joins(:stamp_category)
                            .order("stamp_categories.position ASC, stamps.position ASC, stamps.id ASC")
                            .includes(:stamp_category)

        max_stamp_updated = Stamp.maximum(:updated_at)
        max_cat_updated = StampCategory.maximum(:updated_at)
        stamp_count = Stamp.active.in_active_categories.count

        return unless stale?(etag: [ max_stamp_updated, max_cat_updated, stamp_count, @locale ], public: true)

        @stamps = stamps_scope
      end

      def show
        @locale = I18n.locale
        @stamp = Stamp.includes(:stamp_category).find_by(slug: params[:slug])
        raise Api::NotFoundError, "Stamp not found" if @stamp.nil?

        nil unless stale?(etag: [ @stamp.updated_at, @stamp.stamp_category.updated_at, @locale ], public: true)
      end
    end
  end
end
