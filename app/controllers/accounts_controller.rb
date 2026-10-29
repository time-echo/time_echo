class AccountsController < ApplicationController
  before_action :authenticate_user!

  def show
  end

  def update
    new_email = account_params[:email]&.strip&.downcase

    if new_email.blank? || new_email == current_user_email
      respond_to do |format|
        format.turbo_stream do
          flash.now[:notice] = t("settings.updated_successfully")
          render turbo_stream: [
            turbo_stream.replace("flash-container", partial: "shared/flash")
          ]
        end
        format.html { redirect_to account_path, notice: t("settings.saved_successfully") }
      end
      return
    end

    result = Accounts::RequestEmailUpdateService.call(new_email, current_user_email)

    if result.success?
      redirect_to account_path, notice: t("settings.email_update_requested_message", email: new_email)
    else
      flash.now[:alert] = result.message || result.error
      render :show, status: :unprocessable_entity
    end
  end

  def destroy
    Accounts::DestroyAccountService.call(current_user_email)
    session[:current_user_email] = nil
    redirect_to root_path, notice: t("settings.account_deleted")
  end

  private

  def account_params
    params.permit(:email)
  end
end
