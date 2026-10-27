# frozen_string_literal: true

module Api
  module V1
    class LetterPredictionsController < BaseController
      before_action :authenticate_user!

      def update
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
