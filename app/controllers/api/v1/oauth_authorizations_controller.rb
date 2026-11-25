# frozen_string_literal: true

module Api
  module V1
    class OauthAuthorizationsController < BaseController
      def create
        result = unwrap!(::Oauth::BuildAuthorizationService.call(
          provider: auth_params.require(:provider),
          purpose: auth_params[:purpose].presence || "login",
          user_email: current_user_email
        ))
        render_resource(result, status: :created)
      end

      private

      def auth_params
        params[:oauth_authorization].is_a?(ActionController::Parameters) ? params[:oauth_authorization] : params
      end
    end
  end
end
