# frozen_string_literal: true

module Letters
  class CreateService
    def self.call(params:, current_user_email: nil)
      new(params: params, current_user_email: current_user_email).call
    end

    def initialize(params:, current_user_email: nil)
      @params = params.to_h
      @current_user_email = current_user_email
    end

    def call
      if @current_user_email.present?
        @params[:email] = @current_user_email
      end

      form = LetterForm.new(@params)
      if form.save
        AuditLog.record!(
          action: "letter.created",
          auditable: form.letter,
          actor_email: form.letter.email,
          metadata: {
            scheduled_at: form.letter.scheduled_at&.iso8601,
            language: form.letter.language,
            timezone: form.letter.timezone,
            predictions_count: form.letter.predictions.size
          }
        )

        LetterMailer.stamped_confirmation(form.letter).deliver_later
        ServiceResult.success(letter: form.letter, form: form)
      else
        ServiceResult.failure(:invalid, errors: form.errors, form: form)
      end
    end

    Result = ServiceResult
  end
end
