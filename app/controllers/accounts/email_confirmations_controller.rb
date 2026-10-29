module Accounts
  class EmailConfirmationsController < ApplicationController
    def show
      result = Accounts::ConfirmEmailUpdateService.call(params[:token])

      if result.success?
        session[:current_user_email] = result.new_email
        redirect_to account_path, notice: t("settings.email_confirmed")
      else
        redirect_to account_path, alert: t("settings.confirmation_link_invalid")
      end
    end
  end
end
