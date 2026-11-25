# frozen_string_literal: true

module Api
  module V1
    module Accounts
      class IdentitiesController < BaseController
        before_action :authenticate_user!

        def index
          user = User.find_by(email: current_user_email)
          identities = user ? user.identities.order(:provider).to_a : []
          has_password = user&.has_password? || false
          methods_count = (has_password ? 1 : 0) + identities.size

          render_resource(
            {
              has_password: has_password,
              can_unlink: methods_count > 1,
              identities: identities.map do |identity|
                {
                  provider: identity.provider,
                  email: identity.email,
                  linked_at: identity.created_at.iso8601
                }
              end
            },
            status: :ok
          )
        end

        def create
          result = unwrap!(::Oauth::BuildAuthorizationService.call(
            provider: identity_params.require(:provider),
            purpose: "link",
            user_email: current_user_email
          ))
          render_resource(result, status: :created)
        end

        def destroy
          result = unwrap!(::Oauth::UnlinkIdentityService.call(
            email: current_user_email,
            provider: params[:provider]
          ))
          render_resource(result, status: :ok)
        end

        private

        def identity_params
          params[:identity].is_a?(ActionController::Parameters) ? params[:identity] : params
        end
      end
    end
  end
end
