# frozen_string_literal: true

module Api
  module V1
    module Accounts
      class PasswordsController < BaseController
        before_action :authenticate_user!

        def update
          result = unwrap!(::Settings::UpdatePasswordService.call(
            email: current_user_email,
            current_password: password_params[:current_password],
            password: password_params.require(:password),
            password_confirmation: password_params[:password_confirmation],
            current_token: extract_bearer_token || request.headers["X-Session-Token"]
          ))
          render_resource(result, status: :ok)
        end

        private

        def password_params
          params[:account].is_a?(ActionController::Parameters) ? params[:account] : params
        end
      end
    end
  end
end
