# frozen_string_literal: true

module Api
  module V1
    class StampsController < BaseController
      def index
        @locale = I18n.locale
        scope = Stamp.joins(:stamp_category).includes(:stamp_category)

        if params[:active].present? || params[:status].present?
          scope = scope.filter_by_status(params[:active] || params[:status])
        else
          scope = scope.active.in_active_categories
        end

        scope = scope.by_category(params[:category] || params[:category_id] || params[:category_slug])
        scope = scope.search_by_name(params[:name] || params[:q] || params[:query])
        scope = scope.order("stamp_categories.position ASC, stamps.position ASC, stamps.id ASC")

        filter_cache_key = [
          params[:active], params[:status],
          params[:category], params[:category_id], params[:category_slug],
          params[:name], params[:q], params[:query],
          params[:page], params[:per_page] || params[:perPage]
        ].compact.join(":")

        max_stamp_updated = Stamp.maximum(:updated_at)
        max_cat_updated = StampCategory.maximum(:updated_at)
        count = scope.count

        return unless stale?(etag: [ max_stamp_updated, max_cat_updated, count, @locale, filter_cache_key ], public: true)

        @stamps = paginate(scope)
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
