# frozen_string_literal: true

module Api
  module V1
    class RegistrationsController < BaseController
      def create
        @registration_data = unwrap!(::Auth::RegisterService.call(
          email: email_param,
          password: password_param,
          password_confirmation: password_confirmation_param,
          locale: locale_param
        ))

        if @registration_data[:requires_email_verification]
          render_resource(@registration_data, status: :accepted)
        else
          session[:current_user_email] = @registration_data[:email]
          render_resource(@registration_data, status: :created)
        end
      end

      private

      def registration_params
        params[:registration].is_a?(ActionController::Parameters) ? params[:registration] : params
      end

      def email_param
        registration_params.require(:email)
      end

      def password_param
        registration_params.require(:password)
      end

      def password_confirmation_param
        registration_params[:password_confirmation]
      end

      def locale_param
        extract_valid_locale(registration_params[:locale]) ||
          extract_valid_locale(request.headers["X-Locale"])
      end
    end
  end
end
