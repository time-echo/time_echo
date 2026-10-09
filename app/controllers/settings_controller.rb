class SettingsController < ApplicationController
  before_action :authenticate_user!

  def show
    @account_created_at = Letter.where(email: current_user_email).order(:created_at).first&.created_at || Time.current
  end

  def update
    new_email = settings_params[:email]&.strip&.downcase

    if new_email.blank? || new_email == current_user_email
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = t("settings.updated_successfully")
          render turbo_stream: [
            turbo_stream.replace("flash-container", partial: "shared/flash")
          ]
        end
        format.html { redirect_to settings_path, notice: t("settings.saved_successfully") }
      end
      return
    end

    result = Settings::RequestEmailUpdateService.call(new_email, current_user_email)

    if result.success?
      redirect_to settings_path, notice: t("settings.email_update_requested_message", email: new_email)
    else
      flash.now[:alert] = result.error
      @account_created_at = Letter.where(email: current_user_email).order(:created_at).first&.created_at || Time.current
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    Settings::DestroyAccountService.call(current_user_email)
    session[:current_user_email] = nil
    redirect_to root_path, notice: t("settings.account_deleted")
  end

  private

  def settings_params
    params.permit(:email)
  end
end
