# frozen_string_literal: true

module Api
  module V1
    class InspirationsController < BaseController
      def index
        @locale = I18n.locale
        scope = Inspiration.all

        if params[:active].present? || params[:status].present?
          scope = scope.filter_by_status(params[:active] || params[:status])
        else
          scope = scope.active
        end

        scope = scope.search_by_text(params[:text] || params[:q] || params[:query])
        scope = scope.ordered

        filter_cache_key = [
          params[:active], params[:status],
          params[:text], params[:q], params[:query],
          params[:page], params[:per_page] || params[:perPage]
        ].compact.join(":")

        max_inspiration_updated = Inspiration.maximum(:updated_at)
        count = scope.count

        return unless stale?(etag: [ max_inspiration_updated, count, @locale, filter_cache_key ], public: true)

        @inspirations = paginate(scope)
      end

      def show
        @locale = I18n.locale
        @inspiration = Inspiration.find_by(slug: params[:slug])
        raise Api::NotFoundError, "Inspiration not found" if @inspiration.nil?

        nil unless stale?(etag: [ @inspiration.updated_at, @locale ], public: true)
      end
    end
  end
end
