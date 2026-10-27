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
        return Result.new(success: false, error: :not_found)
      end

      policy = LetterPolicy.new(@current_user_email, letter)
      unless policy.show?
        return Result.new(success: false, error: :unauthorized)
      end

      Letter.transaction do
        update_attrs = {
          reveal_happiness: @params[:reveal_happiness],
          reveal_anxiety: @params[:reveal_anxiety],
          reveal_motivation: @params[:reveal_motivation]
        }
        if @params[:opened_at].present? || @params[:is_wax_broken].present?
          update_attrs[:opened_at] = @params[:opened_at] || letter.opened_at || Time.current
        end

        letter.update!(update_attrs.compact)

        if @params[:predictions].present?
          if @params[:predictions].is_a?(Array)
            @params[:predictions].each do |pred_params|
              prediction = letter.predictions.find_by(id: pred_params[:id])
              if prediction
                prediction.update!(
                  reality: pred_params[:reality],
                  matched: ActiveModel::Type::Boolean.new.cast(pred_params[:matched])
                )
              end
            end
          else
            @params[:predictions].each do |pred_id, pred_params|
              prediction = letter.predictions.find_by(id: pred_id)
              if prediction
                prediction.update!(
                  reality: pred_params[:reality],
                  matched: ActiveModel::Type::Boolean.new.cast(pred_params[:matched])
                )
              end
            end
          end
        end

        Analytics::TrackEventService.call("prediction_completion", { letter_id: letter.id, email: letter.email })
        Analytics::TrackEventService.call("emotional_snapshot_completion", { letter_id: letter.id, email: letter.email })
      end

      Result.new(success: true, letter: letter)
    rescue ActiveRecord::RecordInvalid => e
      Result.new(success: false, error: :invalid, message: e.message)
    end

    private

    def find_letter
      Letter.find_signed(@letter_id_or_signed_id.to_s) || Letter.find_by(id: @letter_id_or_signed_id)
    end

    class Result
      attr_reader :letter, :error, :message
      def initialize(success:, letter: nil, error: nil, message: nil)
        @success = success
        @letter = letter
        @error = error
        @message = message
      end

      def success?
        @success
      end
    end
  end
end
