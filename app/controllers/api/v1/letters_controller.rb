# frozen_string_literal: true

module Api
  module V1
    class LettersController < BaseController
      before_action :authenticate_user!, only: [ :index, :destroy ]

      def index
        scope = if params[:status] == "archived" || params[:archived] == "true"
          Letter.archived.for_email(current_user_email)
        else
          UserTimelineQuery.call(current_user_email)
        end

        scope = scope.includes(:emotional_snapshot, :predictions)
        @pagy, @letters = pagy(scope, limit: per_page)

        Analytics::TrackEventService.call("dashboard_viewed", { email: current_user_email })
      end

      def show
        result = handle_service_result!(
          Letters::AccessService.call(params[:id], current_user_email, include_archived: true),
          unauthorized: I18n.t("flash.unauthorized_view")
        )
        @letter = result.letter
      end

      def create
        result = handle_service_result!(
          Letters::CreateService.call(
            params: letter_params,
            current_user_email: current_user_email
          )
        )
        @letter = result.letter
        render :show, status: :created
      end

      def destroy
        handle_service_result!(Letters::DestroyService.call(params[:id], current_user_email))
        head :no_content
      end

      private

      def letter_params
        raw = params[:letter].present? ? params.require(:letter) : params
        raw.permit(
          :title, :email, :content, :deliver_at, :scheduled_at, :timezone, :language,
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
