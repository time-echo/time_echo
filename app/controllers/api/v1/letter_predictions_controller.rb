module Api
  module V1
    class LetterPredictionsController < BaseController
      before_action :authenticate_user!

      def update
        result = Letters::UpdatePredictionsService.call(
          params[:letter_id],
          prediction_params,
          current_user_email
        )

        if result.success?
          @letter = result.letter
          render "api/v1/letters/show", status: :ok
        else
          case result.error
          when :not_found
            render json: { error: "not_found", message: I18n.t("flash.private_or_inaccessible") }, status: :not_found
          when :unauthorized
            render json: { error: "unauthorized", message: I18n.t("flash.unauthorized_modify") }, status: :unauthorized
          else
            render json: { error: "unprocessable_entity", message: result.message || I18n.t("letters.error_saving") }, status: :unprocessable_entity
          end
        end
      end

      private

      def prediction_params
        params.permit(
          :reveal_happiness, :reveal_anxiety, :reveal_motivation,
          :opened_at, :is_wax_broken,
          predictions: [ :id, :reality, :matched ]
        )
      end
    end
  end
end
