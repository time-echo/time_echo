# frozen_string_literal: true

require "posthog"

Rails.application.config.to_prepare do
  Analytics::PosthogService.reset_client! if defined?(Analytics::PosthogService)
end
