module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::Cookies
      include ActionController::RequestForgeryProtection

      protect_from_forgery with: :null_session

      before_action :set_locale
      before_action :set_current_attributes

      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :render_unprocessable_entity
      rescue_from ActionController::ParameterMissing, with: :render_bad_request

      def current_user_email
        @current_user_email ||= resolve_current_user_email
      end

      def user_signed_in?
        current_user_email.present?
      end

      def authenticate_user!
        unless user_signed_in?
          render json: { error: "unauthorized", message: I18n.t("flash.login_required") }, status: :unauthorized
        end
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

      def render_not_found(exception)
        render json: { error: "not_found", message: exception.message }, status: :not_found
      end

      def render_unprocessable_entity(exception)
        render json: {
          error: "unprocessable_entity",
          message: exception.record.errors.full_messages.to_sentence,
          details: exception.record.errors.as_json
        }, status: :unprocessable_entity
      end

      def render_bad_request(exception)
        render json: { error: "bad_request", message: exception.message }, status: :bad_request
      end
    end
  end
end
