# frozen_string_literal: true

module Api
  module V1
    class LetterPredictionsController < BaseController
      before_action :authenticate_user!

      def update
        letter = Letter.find_by(id: params[:letter_id])
        if letter.nil? || letter.email != current_user_email
          raise Api::NotFoundError, I18n.t("flash.private_or_inaccessible", default: "Resource not found")
        end

        @letter = unwrap!(
          ::Letters::UpdatePredictionsService.call(
            params[:letter_id],
            prediction_params,
            current_user_email
          )
        )
        render "api/v1/letters/show", status: :ok
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
