# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection
      include Api::ApiResponse
      include Api::ResultHandler
      include Api::ErrorHandler

      protect_from_forgery with: :null_session

      before_action :set_locale
      before_action :set_current_attributes

      def current_user_email
        @current_user_email ||= resolve_current_user_email
      end

      def user_signed_in?
        current_user_email.present?
      end

      def authenticate_user!
        unless user_signed_in?
          raise Api::UnauthorizedError, I18n.t("flash.login_required")
        end
      end

      def route_not_found
        raise Api::NotFoundError, "No route matches [#{request.method}] #{request.path}"
      end

      private

      def resolve_current_user_email
        if session[:current_user_email].present?
          return session[:current_user_email]
        end

        token = extract_bearer_token || request.headers["X-Session-Token"]
        if token.present?
          session_token = SessionToken.active.find_by(token: token)
          return session_token&.email
        end

        nil
      end

      def extract_bearer_token
        header = request.headers["Authorization"]
        return nil if header.blank?

        header.start_with?("Bearer ") ? header.split(" ", 2).last : nil
      end

      def set_locale
        locale = request.headers["X-Locale"]&.to_sym
        if locale.nil? || !I18n.available_locales.include?(locale)
          locale = session[:locale]&.to_sym
        end
        if locale.nil? || !I18n.available_locales.include?(locale)
          locale = request.env["HTTP_ACCEPT_LANGUAGE"]&.scan(/^[a-z]{2}/)&.first&.to_sym
        end

        I18n.locale = (locale && I18n.available_locales.include?(locale)) ? locale : I18n.default_locale
      end

      def set_current_attributes
        Current.ip_address = request.remote_ip
        Current.user_agent = request.user_agent
      end
    end
  end
end
