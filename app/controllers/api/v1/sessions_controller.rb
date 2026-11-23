# frozen_string_literal: true

module Api
  module V1
    class SessionsController < BaseController
      before_action :authenticate_user!, only: [ :me, :destroy ]

      def create
        if password_param.present?
          @session_data = unwrap!(::Auth::PasswordLoginService.call(
            email: email_param,
            password: password_param
          ))
          session[:current_user_email] = @session_data[:email]
          render :show, status: :created
        else
          @session_data = unwrap!(::Auth::RequestMagicLinkService.call(
            email: email_param,
            locale: locale_param
          ))
          render :create, status: :created
        end
      end

      def show
        token = params[:token] || params[:id]
        @session_data = unwrap!(::Auth::AuthenticateTokenService.call(token: token))
        session[:current_user_email] = @session_data[:email]
        render :show, status: :ok
      end

      def me
        @email = current_user_email
        @user = User.find_by(email: @email)
        @identities = @user ? @user.identities.order(:provider).to_a : []
        render :me, status: :ok
      end

      def destroy
        token = extract_bearer_token || request.headers["X-Session-Token"]
        unwrap!(::Auth::DestroySessionService.call(email: current_user_email, token: token))
        session.delete(:current_user_email)
        render_no_content
      end

      private

      def email_param
        if params.key?(:email)
          params[:email]
        elsif params[:session].present?
          params.require(:session).require(:email)
        else
          params.require(:email)
        end
      end

      def password_param
        if params.key?(:password)
          params[:password]
        elsif params[:session].is_a?(ActionController::Parameters)
          params[:session][:password]
        end
      end

      def locale_param
        extract_valid_locale(params[:locale]) ||
          extract_valid_locale(params.dig(:session, :locale)) ||
          extract_valid_locale(request.headers["X-Locale"])
      end
    end
  end
end
