# frozen_string_literal: true

module Api
  module V1
    class AccountsController < BaseController
      before_action :authenticate_user!

      def update
        @account_data = unwrap!(::Accounts::RequestEmailUpdateService.call(email_param, current_user_email))
        render :update, status: :ok
      end

      def destroy
        unwrap!(::Accounts::DestroyAccountService.call(current_user_email))
        session.delete(:current_user_email)
        render_no_content
      end

      private

      def email_param
        if params.key?(:email)
          params[:email]
        elsif params[:account].present?
          params.require(:account).permit(:email)[:email]
        else
          params.require(:email)
        end
      end
    end
  end
end
