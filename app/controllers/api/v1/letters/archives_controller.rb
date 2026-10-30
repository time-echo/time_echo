# frozen_string_literal: true

module Api
  module V1
    module Letters
      class ArchivesController < BaseController
        before_action :authenticate_user!

        def create
          find_owned_letter!(params[:letter_id])
          @letter = unwrap!(
            ::Letters::ArchiveService.call(params[:letter_id], current_user_email)
          )
          render "api/v1/letters/show", status: :ok
        end
      end
    end
  end
end
