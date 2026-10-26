module Api
  module V1
    module Letters
      class RestoresController < BaseController
        before_action :authenticate_user!

        def create
          result = ::Letters::RestoreService.call(params[:letter_id], current_user_email)

          if result.success?
            @letter = result.letter
            render "api/v1/letters/show", status: :ok
          else
            case result.error
            when :not_found
              render json: { error: "not_found", message: I18n.t("flash.private_or_inaccessible") }, status: :not_found
            when :unauthorized
              render json: { error: "unauthorized", message: I18n.t("flash.unauthorized_action") }, status: :unauthorized
            when :cannot_restore
              render json: { error: "cannot_restore", message: I18n.t("flash.cannot_restore") }, status: :unprocessable_entity
            end
          end
        end
      end
    end
  end
end
