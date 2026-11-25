# frozen_string_literal: true

require "json"
require "net/http"
require "uri"

module Oauth
  module Providers
    class Base
      class ProviderError < StandardError
        attr_reader :code

        def initialize(message, code: :oauth_failed)
          super(message)
          @code = code
        end
      end

      HTTP_TIMEOUT = 10

      def self.web_app_url
        host = ENV.fetch("APP_HOST", "localhost:3001").strip.chomp("/")
        host.match?(%r{\Ahttps?://}i) ? host : "#{ENV.fetch('APP_PROTOCOL', 'http')}://#{host}"
      end

      def self.redirect_uri_for(provider)
        "#{web_app_url}/api/auth/oauth/#{provider}/callback"
      end

      protected

      def fetch_credential(env_key, *cred_path)
        ENV[env_key].presence || read_rails_credential(*cred_path)
      end

      def read_rails_credential(*path)
        Rails.application.credentials.dig(*path).presence
      rescue ActiveSupport::EncryptedFile::MissingKeyError
        nil
      end

      def http_post_form(url, params)
        uri = URI.parse(url)
        request = Net::HTTP::Post.new(uri)
        request.set_form_data(params)
        request["Accept"] = "application/json"
        perform_json_request(uri, request)
      end

      def http_get_json(url, headers: {}, params: {})
        uri = URI.parse(url)
        if params.any?
          existing = URI.decode_www_form(uri.query || "")
          params.each { |k, v| existing << [ k.to_s, v.to_s ] }
          uri.query = URI.encode_www_form(existing)
        end

        request = Net::HTTP::Get.new(uri)
        request["Accept"] = "application/json"
        headers.each { |k, v| request[k] = v }
        perform_json_request(uri, request)
      end

      def perform_json_request(uri, request)
        response = Net::HTTP.start(
          uri.host,
          uri.port,
          use_ssl: uri.scheme == "https",
          open_timeout: HTTP_TIMEOUT,
          read_timeout: HTTP_TIMEOUT
        ) do |http|
          http.request(request)
        end

        parsed = JSON.parse(response.body.to_s)
        unless response.is_a?(Net::HTTPSuccess)
          error_desc = parsed["error_description"] || parsed.dig("error", "message") || parsed["error"] || "OAuth provider error"
          raise ProviderError.new(error_desc.to_s, code: :oauth_failed)
        end

        parsed
      rescue JSON::ParserError, SocketError, Timeout::Error, Errno::ECONNREFUSED, OpenSSL::SSL::SSLError => e
        raise ProviderError.new("OAuth provider communication failed: #{e.message}", code: :oauth_failed)
      end
    end
  end
end
