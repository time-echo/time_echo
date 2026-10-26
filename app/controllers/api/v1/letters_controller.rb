module Api
  module V1
    class LettersController < BaseController
      before_action :authenticate_user!, only: [ :index, :destroy ]

      def index
        @letters = if params[:status] == "archived" || params[:archived] == "true"
          Letter.archived.for_email(current_user_email)
        else
          UserTimelineQuery.call(current_user_email)
        end

        Analytics::TrackEventService.call("dashboard_viewed", { email: current_user_email })
      end

      def show
        result = Letters::AccessService.call(params[:id], current_user_email, include_archived: true)

        if result.success?
          @letter = result.letter
        else
          case result.error
          when :not_found
            render json: { error: "not_found", message: I18n.t("flash.private_or_inaccessible") }, status: :not_found
          when :unauthorized
            render json: { error: "unauthorized", message: I18n.t("flash.unauthorized_view") }, status: :unauthorized
          end
        end
      end

      def create
        result = Letters::CreateService.call(
          params: letter_params,
          current_user_email: current_user_email
        )

        if result.success?
          @letter = result.letter
          render :show, status: :created
        else
          render json: {
            error: "unprocessable_entity",
            message: result.errors.full_messages.to_sentence,
            details: result.errors.as_json
          }, status: :unprocessable_entity
        end
      end

      def destroy
        result = Letters::DestroyService.call(params[:id], current_user_email)

        if result.success?
          head :no_content
        else
          case result.error
          when :not_found
            render json: { error: "not_found", message: I18n.t("flash.private_or_inaccessible") }, status: :not_found
          when :unauthorized
            render json: { error: "unauthorized", message: I18n.t("flash.unauthorized_action") }, status: :unauthorized
          when :cannot_delete
            render json: { error: "cannot_delete", message: I18n.t("flash.cannot_delete") }, status: :unprocessable_entity
          end
        end
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
