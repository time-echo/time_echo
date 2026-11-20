# frozen_string_literal: true

require "openssl"

module Analytics
  class UserIdentifier
    PREFIX = "usr_"

    def self.for(identifier)
      new(identifier).call
    end

    def self.call(identifier)
      new(identifier).call
    end

    def initialize(identifier)
      @identifier = identifier.to_s.strip
    end

    def call
      return nil if @identifier.blank?
      return @identifier if @identifier.start_with?(PREFIX) && !@identifier.include?("@")

      normalized = @identifier.downcase
      digest = OpenSSL::HMAC.hexdigest("SHA256", secret_key, normalized)
      "#{PREFIX}#{digest[0, 32]}"
    end

    private

    # HMAC secret stored in per-environment Rails credentials:
    #   bin/rails credentials:edit --environment production
    #   analytics:
    #     user_id_secret: <openssl rand -hex 32>
    def secret_key
      Rails.application.credentials.dig(:analytics, :user_id_secret).presence ||
        Rails.application.secret_key_base.presence ||
        "time_echo_analytics_default_key"
    end
  end
end
