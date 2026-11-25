# frozen_string_literal: true

module Api
  module V1
    class PasswordResetsController < BaseController
      def create
        result = unwrap!(::Auth::RequestPasswordResetService.call(
          email: email_param,
          locale: locale_param
        ))
        render_resource(result, status: :ok)
      end

      def update
        result = unwrap!(::Auth::ResetPasswordService.call(
          token: params[:token],
          password: password_param,
          password_confirmation: password_confirmation_param
        ))
        render_resource(result, status: :ok)
      end

      private

      def reset_params
        params[:password_reset].is_a?(ActionController::Parameters) ? params[:password_reset] : params
      end

      def email_param
        reset_params.require(:email)
      end

      def password_param
        reset_params.require(:password)
      end

      def password_confirmation_param
        reset_params[:password_confirmation]
      end

      def locale_param
        extract_valid_locale(reset_params[:locale]) ||
          extract_valid_locale(request.headers["X-Locale"])
      end
    end
  end
end
