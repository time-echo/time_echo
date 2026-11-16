# frozen_string_literal: true

module Health
  class CheckService
    def self.call
      new.call
    end

    def call
      checks = {}
      all_healthy = true

      db_status, db_latency, db_error = check_database
      checks[:database] = { status: db_status }
      checks[:database][:latency_ms] = db_latency if db_latency
      if db_error
        checks[:database][:error] = db_error
        all_healthy = false
      end

      migrations_status, migrations_error = check_migrations
      checks[:migrations] = { status: migrations_status }
      if migrations_error
        checks[:migrations][:error] = migrations_error
        all_healthy = false
      end

      jobs_status, jobs_error = check_jobs
      checks[:jobs] = { status: jobs_status }
      if jobs_error
        checks[:jobs][:error] = jobs_error
        all_healthy = false
      end

      if all_healthy
        ServiceResult.success(
          {
            status: "healthy",
            timestamp: Time.current.iso8601,
            version: "1.0.0",
            services: checks
          }
        )
      else
        failed_services = checks.select { |_k, v| v[:status] != "ok" && v[:status] != "up_to_date" }.keys
        ServiceResult.failure(
          :service_unavailable,
          message: "Health check failed for: #{failed_services.join(', ')}",
          details: checks
        )
      end
    end

    private

    def check_database
      t0 = Process.clock_gettime(Process::CLOCK_MONOTONIC)
      ActiveRecord::Base.connection.execute("SELECT 1")
      latency = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - t0) * 1000).round(2)
      [ "ok", latency, nil ]
    rescue StandardError => e
      [ "unhealthy", nil, e.message ]
    end

    def check_migrations
      ActiveRecord::Migration.check_all_pending!
      [ "up_to_date", nil ]
    rescue ActiveRecord::PendingMigrationError => e
      [ "pending_migrations", e.message ]
    rescue StandardError => e
      [ "unhealthy", e.message ]
    end

    def check_jobs
      if ActiveRecord::Base.connection.table_exists?(:good_jobs)
        [ "ok", nil ]
      else
        [ "unhealthy", "GoodJob table does not exist" ]
      end
    rescue StandardError => e
      [ "unhealthy", e.message ]
    end

    Result = ServiceResult
  end
end
