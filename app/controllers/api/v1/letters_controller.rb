# frozen_string_literal: true

module Api
  module V1
    class LettersController < BaseController
      before_action :authenticate_user!, only: [ :index, :show, :destroy ]

      def index
        requested_status = params[:archived] == "true" ? "archived" : params[:status]
        scope = ::UserTimelineQuery.call(current_user_email, status: requested_status)
        scope = scope.includes(:emotional_snapshot, :predictions, stamp: :stamp_category)
        @letters = paginate(scope)

        ::Analytics::TrackEventService.call("dashboard_viewed", { email: current_user_email })
      end

      def show
        @letter = unwrap!(
          ::Letters::AccessService.call(params[:id], current_user_email, include_archived: true)
        )
      end

      def create
        @letter = unwrap!(
          ::Letters::CreateService.call(
            params: letter_params,
            current_user_email: current_user_email
          )
        )
        render :show, status: :created
      end

      def destroy
        unwrap!(::Letters::DestroyService.call(params[:id], current_user_email))
        render_no_content
      end

      private

      def letter_params
        raw = params[:letter].present? ? params.require(:letter) : params
        raw.permit(
          :title, :email, :content, :deliver_at, :scheduled_at, :timezone, :language,
          :stamp_slug, :stamp_id, :stampId,
          :happiness_level, :anxiety_level, :motivation_level,
          :prediction_city, :prediction_salary, :prediction_relationship,
          :prediction_career, :prediction_achievement, :prediction_happiness,
          emotional_snapshot_attributes: [ :happiness_level, :anxiety_level, :motivation_level ],
          predictions_attributes: [ :category, :prediction ]
        )
      end
    end
  end
end
