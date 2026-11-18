# frozen_string_literal: true

require "posthog"

module Analytics
  class PosthogService
    PRODUCT_EVENTS = %w[
      letter_creation_started
      stamp_selected
      letter_creation_completed
      letter_saved
      letter_scheduled
      letter_shared
      letter_viewed
      user_logged_in
      user_signed_up
    ].freeze

    SENSITIVE_KEYS = %w[
      email
      user_email
      old_email
      new_email
      actor_email
      recipient_email
      name
      first_name
      last_name
      password
      token
      session_token
      magic_link_token
      authorization
      content
      title
      body
      prediction
      predictions
      prediction_city
      prediction_salary
      prediction_relationship
      prediction_career
      prediction_achievement
      prediction_happiness
      reality
      ip
      ip_address
    ].freeze

    EMAIL_PATTERN = /\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b/i

    class << self
      attr_writer :client

      def enabled?
        return false if disabled_environment?
        return false if ENV["ANALYTICS_ENABLED"]&.downcase == "false"

        api_key.present?
      end

      def analytics_environment
        ENV["ANALYTICS_ENVIRONMENT"].presence ||
          ENV["RAILS_ENV"].presence ||
          Rails.env.to_s
      end

      def api_key
        ENV["POSTHOG_API_KEY"].to_s.strip.presence
      end

      def host
        ENV.fetch("POSTHOG_HOST", "https://us.i.posthog.com").to_s.strip
      end

      def client
        return @client if defined?(@client) && !@client.nil?
        return nil unless enabled?

        @client = PostHog::Client.new(
          api_key: api_key,
          host: host,
          on_error: proc { |status, msg|
            Rails.logger.warn("[Analytics::PosthogService] PostHog API error (#{status}): #{msg}")
          }
        )
      rescue StandardError => e
        Rails.logger.warn("[Analytics::PosthogService] Client init failed: #{e.class} - #{e.message}")
        nil
      end

      def reset_client!
        @client = nil
      end

      def track(event:, user_id: nil, email: nil, properties: {}, async: true)
        event_name = event.to_s.strip
        return false if event_name.blank?

        distinct_id = resolve_distinct_id(user_id: user_id, email: email)
        return false if distinct_id.blank?
        return false unless enabled?

        sanitized = sanitize_properties(properties)

        if async
          Analytics::CaptureEventJob.perform_later(
            action_type: "capture",
            event: event_name,
            distinct_id: distinct_id,
            properties: sanitized,
            occurred_at: Time.current.iso8601
          )
          true
        else
          capture_now(
            event: event_name,
            distinct_id: distinct_id,
            properties: sanitized,
            occurred_at: Time.current
          )
        end
      rescue StandardError => e
        Rails.logger.warn("[Analytics::PosthogService] Track failed (#{event}): #{e.class} - #{e.message}")
        false
      end

      def identify(user_id: nil, email: nil, properties: {}, async: true)
        distinct_id = resolve_distinct_id(user_id: user_id, email: email)
        return false if distinct_id.blank?
        return false unless enabled?

        sanitized = sanitize_properties(properties, include_source: false)

        if async
          Analytics::CaptureEventJob.perform_later(
            action_type: "identify",
            distinct_id: distinct_id,
            properties: sanitized,
            occurred_at: Time.current.iso8601
          )
          true
        else
          identify_now(distinct_id: distinct_id, properties: sanitized)
        end
      rescue StandardError => e
        Rails.logger.warn("[Analytics::PosthogService] Identify failed: #{e.class} - #{e.message}")
        false
      end

      def capture_now(event:, distinct_id:, properties: {}, occurred_at: nil)
        return false if event.blank? || distinct_id.blank?

        ph_client = client
        return false if ph_client.nil?

        sanitized = sanitize_properties(properties)
        payload = {
          distinct_id: distinct_id.to_s,
          event: event.to_s,
          properties: sanitized
        }
        if occurred_at.present?
          parsed_time = occurred_at.is_a?(String) ? Time.zone.parse(occurred_at) : occurred_at
          payload[:timestamp] = parsed_time if parsed_time
        end

        ph_client.capture(payload)
        true
      rescue StandardError => e
        Rails.logger.warn("[Analytics::PosthogService] Capture failed (#{event}): #{e.class} - #{e.message}")
        false
      end

      def identify_now(distinct_id:, properties: {})
        return false if distinct_id.blank?

        ph_client = client
        return false if ph_client.nil?

        sanitized = sanitize_properties(properties, include_source: false)
        ph_client.identify(
          distinct_id: distinct_id.to_s,
          properties: sanitized
        )
        true
      rescue StandardError => e
        Rails.logger.warn("[Analytics::PosthogService] Identify now failed: #{e.class} - #{e.message}")
        false
      end

      def track_letter_shared(letter:, actor_email: nil, share_method: "link", async: true)
        return false if letter.nil?

        track(
          event: "letter_shared",
          email: actor_email.presence || letter.email,
          properties: {
            letter_id: letter.id.to_s,
            share_method: share_method.to_s,
            language: letter.language
          },
          async: async
        )
      end

      def sanitize_properties(raw_properties, include_source: true)
        props = (raw_properties || {}).to_h
        cleaned = {}

        props.each do |key, value|
          normalized_key = key.to_s.strip
          next if normalized_key.blank?
          next if SENSITIVE_KEYS.include?(normalized_key.downcase)

          cleaned[normalized_key] = sanitize_value(value)
        end

        cleaned["environment"] ||= analytics_environment
        cleaned["source"] ||= "backend" if include_source
        cleaned
      end

      def resolve_distinct_id(user_id: nil, email: nil)
        return user_id.to_s.strip if user_id.present? && !user_id.to_s.include?("@")

        Analytics::UserIdentifier.for(user_id.presence || email)
      end

      private

      def disabled_environment?
        env = analytics_environment.downcase
        (env == "development" || env == "test") && ENV["ANALYTICS_FORCE_ENABLED"] != "true"
      end

      def sanitize_value(value)
        case value
        when String
          value.gsub(EMAIL_PATTERN, "[REDACTED]")
        when Symbol
          value.to_s
        when Numeric, TrueClass, FalseClass, NilClass
          value
        when Array
          value.map { |item| sanitize_value(item) }
        when Hash
          sanitize_properties(value, include_source: false)
        else
          value.to_s.gsub(EMAIL_PATTERN, "[REDACTED]")
        end
      end
    end
  end
end
