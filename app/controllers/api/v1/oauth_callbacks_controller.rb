# frozen_string_literal: true

module Api
  module V1
    class OauthCallbacksController < BaseController
      def create
        result = unwrap!(::Oauth::CompleteLoginService.call(
          provider: callback_params.require(:provider),
          code: callback_params[:code],
          state: callback_params.require(:state)
        ))

        if result[:purpose] == "login" && result[:email].present?
          session[:current_user_email] = result[:email]
        end

        render_resource(result, status: :ok)
      end

      private

      def callback_params
        params[:oauth_callback].is_a?(ActionController::Parameters) ? params[:oauth_callback] : params
      end
    end
  end
end
