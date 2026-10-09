class LetterSuccessesController < ApplicationController
  def show
    @email = flash[:success_email]
    @deliver_at = flash[:success_deliver_at] ? Time.parse(flash[:success_deliver_at]) : nil
    @seal_date_display = I18n.l(Date.current, format: :default)
    @deliver_at_display = @deliver_at ? I18n.l(@deliver_at.to_date, format: :long) : t("letters.success_date_fallback")
    @next_steps_description = next_steps_text

    if @email.nil?
      redirect_to root_path
    end
  end

  private

  def next_steps_text
    return "" unless @email

    t("letters.success_next_desc", email: @email)
  end
end
