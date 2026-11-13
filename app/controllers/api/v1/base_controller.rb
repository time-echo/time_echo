# frozen_string_literal: true

module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection
      include Api::ApiResponse
      include Api::ResultHandler
      include Api::ErrorHandler

      protect_from_forgery with: :null_session, unless: -> { request.format.json? }

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

      def find_owned_letter!(id = params[:letter_id] || params[:id])
        letter = Letter.find_by(id: id)
        raise Api::NotFoundError if letter.nil? || letter.email != current_user_email

        letter
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
        locale = extract_valid_locale(request.headers["X-Locale"]) ||
                 extract_valid_locale(params[:locale] || params.dig(:letter, :language)) ||
                 extract_valid_locale(session[:locale]) ||
                 extract_valid_locale(request.env["HTTP_ACCEPT_LANGUAGE"])

        I18n.locale = locale || I18n.default_locale
      end

      def extract_valid_locale(raw)
        return nil if raw.blank?

        code = raw.to_s.scan(/^[a-z]{2}/i).first&.downcase&.to_sym
        code if code && I18n.available_locales.include?(code)
      end

      def set_current_attributes
        Current.ip_address = request.remote_ip
        Current.user_agent = request.user_agent
      end
    end
  end
end
