module Settings
  class EmailConfirmationsController < ApplicationController
    def show
      result = Settings::ConfirmEmailUpdateService.call(params[:token])

      if result.success?
        session[:current_user_email] = result.new_email
        redirect_to settings_path, notice: t("settings.email_confirmed")
      else
        redirect_to settings_path, alert: t("settings.confirmation_link_invalid")
      end
    end
  end
end
