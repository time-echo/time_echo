# frozen_string_literal: true

module Api
  module V1
    class InspirationsController < BaseController
      def index
        @locale = I18n.locale
        scope = Inspiration.joins(:inspiration_category).includes(:inspiration_category)

        if params[:active].present? || params[:status].present?
          scope = scope.filter_by_status(params[:active] || params[:status])
        else
          scope = scope.active.in_active_categories
        end

        scope = scope.by_category(params[:category] || params[:category_id] || params[:category_slug])
        scope = scope.search_by_text(params[:text] || params[:q] || params[:query])
        scope = scope.order("inspiration_categories.position ASC, inspirations.position ASC, inspirations.id ASC")

        filter_cache_key = [
          params[:active], params[:status],
          params[:category], params[:category_id], params[:category_slug],
          params[:text], params[:q], params[:query],
          params[:page], params[:per_page] || params[:perPage]
        ].compact.join(":")

        max_inspiration_updated = Inspiration.maximum(:updated_at)
        max_cat_updated = InspirationCategory.maximum(:updated_at)
        count = scope.count

        return unless stale?(etag: [ max_inspiration_updated, max_cat_updated, count, @locale, filter_cache_key ], public: true)

        @inspirations = paginate(scope)
      end

      def show
        @locale = I18n.locale
        @inspiration = Inspiration.includes(:inspiration_category).find_by(slug: params[:slug])
        raise Api::NotFoundError, "Inspiration not found" if @inspiration.nil?

        nil unless stale?(etag: [ @inspiration.updated_at, @inspiration.inspiration_category&.updated_at, @locale ], public: true)
      end
    end
  end
end
