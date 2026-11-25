# frozen_string_literal: true

module Oauth
  class ProviderRegistry
    PROVIDERS = {
      "google" => Providers::Google
      # Facebook login temporarily disabled:
      # "facebook" => Providers::Facebook
    }.freeze

    def self.fetch(provider_name)
      klass = PROVIDERS[provider_name.to_s.strip.downcase]
      klass&.new
    end
  end
end
