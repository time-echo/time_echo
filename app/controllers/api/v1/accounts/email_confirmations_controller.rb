# frozen_string_literal: true

module Api
  module V1
    module Accounts
      class EmailConfirmationsController < BaseController
        def show
          @account_data = unwrap!(::Accounts::ConfirmEmailUpdateService.call(params[:token]))
          session[:current_user_email] = @account_data[:email]
          render "api/v1/accounts/update", status: :ok
        end

        def create
          @account_data = unwrap!(::Accounts::ConfirmEmailUpdateService.call(params[:token]))
          session[:current_user_email] = @account_data[:email]
          render "api/v1/accounts/update", status: :ok
        end
      end
    end
  end
end
