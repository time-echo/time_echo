# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class HealthControllerTest < ActionDispatch::IntegrationTest
      test "GET /api/v1/health/liveness returns 200 and alive status" do
        get "/api/v1/health/liveness", as: :json

        body = assert_resource_response(expected_status: :ok)
        assert_equal "alive", body.dig("data", "status")
        assert body.dig("data", "timestamp").present?
        assert_equal({}, body["meta"])
      end

      test "GET /livez alias returns 200 and alive status" do
        get "/livez"

        body = assert_resource_response(expected_status: :ok)
        assert_equal "alive", body.dig("data", "status")
      end

      test "GET /api/v1/health returns 200 and healthy checks when dependencies are operational" do
        get "/api/v1/health", as: :json

        body = assert_resource_response(expected_status: :ok)
        assert_equal "healthy", body.dig("data", "status")
        assert_equal "1.0.0", body.dig("data", "version")
        assert body.dig("data", "timestamp").present?

        services = body.dig("data", "services")
        assert_equal "ok", services.dig("database", "status")
        assert services.dig("database", "latencyMs").present?
        assert_equal "up_to_date", services.dig("migrations", "status")
        assert_equal "ok", services.dig("jobs", "status")

        assert body.dig("meta", "totalLatencyMs").present?
      end

      test "GET /readyz alias returns 200 and healthy status" do
        get "/readyz"

        body = assert_resource_response(expected_status: :ok)
        assert_equal "healthy", body.dig("data", "status")
      end

      test "GET /api/v1/health returns 503 when database is unreachable" do
        failed_result = Health::CheckService::Result.new(
          success: false,
          error: :service_unavailable,
          message: "Health check failed for: database",
          details: { database: { status: "unhealthy", error: "Connection refused" } }
        )

        with_stub(Health::CheckService, :call, failed_result) do
          get "/api/v1/health", as: :json

          body = assert_error_response(expected_status: :service_unavailable, expected_code: "service_unavailable")
          assert_includes body.dig("error", "message"), "database"
          assert_equal "unhealthy", body.dig("error", "details", "database", "status")
        end
      end

      test "GET /api/v1/health returns 503 when migrations are pending" do
        failed_result = Health::CheckService::Result.new(
          success: false,
          error: :service_unavailable,
          message: "Health check failed for: migrations",
          details: { migrations: { status: "pending_migrations", error: "Pending migrations" } }
        )

        with_stub(Health::CheckService, :call, failed_result) do
          get "/api/v1/health", as: :json

          body = assert_error_response(expected_status: :service_unavailable, expected_code: "service_unavailable")
          assert_includes body.dig("error", "message"), "migrations"
          assert_equal "pending_migrations", body.dig("error", "details", "migrations", "status")
        end
      end

      private

      def with_stub(target, method_name, return_value_or_proc)
        singleton = target.singleton_class
        original_method = target.method(method_name) if target.respond_to?(method_name)

        singleton.define_method(method_name) do |*args, **kwargs, &block|
          if return_value_or_proc.respond_to?(:call)
            return_value_or_proc.call(*args, **kwargs, &block)
          else
            return_value_or_proc
          end
        end

        yield
      ensure
        if original_method
          singleton.define_method(method_name, original_method)
        else
          singleton.remove_method(method_name)
        end
      end
    end
  end
end
