# frozen_string_literal: true

module Api
  module V1
    module Letters
      class RestoresController < BaseController
        before_action :authenticate_user!

        def create
          @letter = unwrap!(
            ::Letters::RestoreService.call(params[:letter_id], current_user_email)
          )
          render "api/v1/letters/show", status: :ok
        end
      end
    end
  end
end
