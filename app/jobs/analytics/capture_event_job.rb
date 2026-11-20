# frozen_string_literal: true

module Analytics
  class CaptureEventJob < ApplicationJob
    queue_as :default

    discard_on StandardError do |_job, error|
      Rails.logger.warn("[Analytics::CaptureEventJob] Discarded job due to error: #{error.class} - #{error.message}")
    end

    def perform(action_type: "capture", event: nil, distinct_id: nil, properties: {}, occurred_at: nil)
      case action_type.to_s
      when "identify"
        Analytics::PosthogService.identify_now(
          distinct_id: distinct_id,
          properties: properties
        )
      else
        Analytics::PosthogService.capture_now(
          event: event,
          distinct_id: distinct_id,
          properties: properties,
          occurred_at: occurred_at
        )
      end
    rescue StandardError => e
      Rails.logger.warn("[Analytics::CaptureEventJob] Failed to process analytics job: #{e.class} - #{e.message}")
      false
    end
  end
end
