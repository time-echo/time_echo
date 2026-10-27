# frozen_string_literal: true

module Api
  module V1
    module Letters
      class ArchivesController < BaseController
        before_action :authenticate_user!

        def create
          result = handle_service_result!(
            ::Letters::ArchiveService.call(params[:letter_id], current_user_email)
          )

          @letter = result.letter
          render "api/v1/letters/show", status: :ok
        end
      end
    end
  end
end
