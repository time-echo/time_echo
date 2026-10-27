# frozen_string_literal: true

require "test_helper"

module Health
  class CheckServiceTest < ActiveSupport::TestCase
    test "returns success when all subsystem checks pass" do
      result = Health::CheckService.call

      assert result.success?
      assert_equal "healthy", result.value[:status]
      assert_equal "1.0.0", result.value[:version]
      assert_equal "ok", result.value.dig(:services, :database, :status)
      assert result.value.dig(:services, :database, :latency_ms).is_a?(Numeric)
      assert_equal "up_to_date", result.value.dig(:services, :migrations, :status)
      assert_equal "ok", result.value.dig(:services, :jobs, :status)
    end

    test "returns failure when database check raises error" do
      service = Health::CheckService.new
      with_stub(service, :check_database, [ "unhealthy", nil, "PG::ConnectionBad: connection refused" ]) do
        result = service.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "database"
        assert_equal "unhealthy", result.details.dig(:database, :status)
      end
    end

    test "returns failure when migrations check reports pending migrations" do
      service = Health::CheckService.new
      with_stub(service, :check_migrations, [ "pending_migrations", "Pending migrations exist" ]) do
        result = service.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "migrations"
        assert_equal "pending_migrations", result.details.dig(:migrations, :status)
      end
    end

    test "returns failure when background jobs table is missing" do
      service = Health::CheckService.new
      with_stub(service, :check_jobs, [ "unhealthy", "GoodJob table does not exist" ]) do
        result = service.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "jobs"
        assert_equal "unhealthy", result.details.dig(:jobs, :status)
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
