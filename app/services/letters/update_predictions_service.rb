# frozen_string_literal: true

module Letters
  class UpdatePredictionsService
    def self.call(letter_id_or_signed_id, params, current_user_email)
      new(letter_id_or_signed_id, params, current_user_email).call
    end

    def initialize(letter_id_or_signed_id, params, current_user_email)
      @letter_id_or_signed_id = letter_id_or_signed_id
      @params = params
      @current_user_email = current_user_email
    end

    def call
      letter = find_letter

      if letter.nil? || letter.pending?
        return ServiceResult.failure(:not_found)
      end

      policy = LetterPolicy.new(@current_user_email, letter)
      unless policy.show?
        return ServiceResult.failure(:not_found)
      end

      Letter.transaction do
        was_unopened = letter.opened_at.blank?

        update_attrs = {
          reveal_happiness: @params[:reveal_happiness],
          reveal_anxiety: @params[:reveal_anxiety],
          reveal_motivation: @params[:reveal_motivation]
        }
        if @params[:opened_at].present? || @params[:is_wax_broken].present?
          update_attrs[:opened_at] = @params[:opened_at] || letter.opened_at || Time.current
        end

        letter.update!(update_attrs.compact)

        update_predictions!(letter)

        Analytics::TrackEventService.call("letter_opened", { letter_id: letter.id, email: letter.email }) if was_unopened && letter.opened_at.present?
        Analytics::TrackEventService.call("prediction_completion", { letter_id: letter.id, email: letter.email })
        Analytics::TrackEventService.call("emotional_snapshot_completion", { letter_id: letter.id, email: letter.email })
      end

      ServiceResult.success(letter: letter)
    rescue ActiveRecord::RecordInvalid => e
      ServiceResult.failure(:invalid, message: e.message)
    end

    private

    def find_letter
      Letter.find_signed(@letter_id_or_signed_id.to_s) || Letter.find_by(id: @letter_id_or_signed_id)
    end

    def update_predictions!(letter)
      return if @params[:predictions].blank?

      predictions_by_id = letter.predictions.index_by { |p| p.id.to_s }
      boolean_type = ActiveModel::Type::Boolean.new

      if @params[:predictions].is_a?(Array)
        @params[:predictions].each do |pred_params|
          prediction = predictions_by_id[pred_params[:id].to_s]
          next unless prediction

          prediction.update!(
            reality: pred_params[:reality],
            matched: boolean_type.cast(pred_params[:matched])
          )
        end
      else
        @params[:predictions].each do |pred_id, pred_params|
          prediction = predictions_by_id[pred_id.to_s]
          next unless prediction

          prediction.update!(
            reality: pred_params[:reality],
            matched: boolean_type.cast(pred_params[:matched])
          )
        end
      end
    end

    Result = ServiceResult
  end
end
