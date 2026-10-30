# frozen_string_literal: true

module Api
  module ApiResponse
    extend ActiveSupport::Concern
    include Pagy::Backend

    def paginate(scope)
      limit = extract_per_page
      @pagy, records = pagy(scope, limit: limit)
      records
    end

    def render_no_content
      head :no_content
    end

    private

    def extract_per_page
      raw = params[:per_page] || params[:perPage]
      limit = raw.to_i
      limit.positive? ? limit.clamp(1, 100) : 20
    end
  end
end
