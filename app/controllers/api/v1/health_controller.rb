# frozen_string_literal: true

module Api
  module V1
    class HealthController < BaseController
      def show
        start_time = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        @health = unwrap!(::Health::CheckService.call)
        @total_latency_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - start_time) * 1000).round(2)
        render :show, status: :ok
      end

      def liveness
        render :liveness, status: :ok
      end
    end
  end
end
