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

    test "returns failure when database execute raises StandardError" do
      conn = ActiveRecord::Base.connection
      with_stub(conn, :execute, ->(*) { raise StandardError, "PG::ConnectionBad: connection refused" }) do
        result = Health::CheckService.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "database"
        assert_equal "unhealthy", result.details.dig(:database, :status)
        assert_includes result.details.dig(:database, :error), "connection refused"
      end
    end

    test "returns failure when migrations check raises PendingMigrationError" do
      with_stub(ActiveRecord::Migration, :check_all_pending!, -> { raise ActiveRecord::PendingMigrationError.new("Pending migrations exist") }) do
        result = Health::CheckService.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "migrations"
        assert_equal "pending_migrations", result.details.dig(:migrations, :status)
      end
    end

    test "returns failure when migrations check raises StandardError" do
      with_stub(ActiveRecord::Migration, :check_all_pending!, -> { raise StandardError, "Migration check failed" }) do
        result = Health::CheckService.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "migrations"
        assert_equal "unhealthy", result.details.dig(:migrations, :status)
      end
    end

    test "returns failure when background jobs table is missing" do
      conn = ActiveRecord::Base.connection
      with_stub(conn, :table_exists?, false) do
        result = Health::CheckService.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "jobs"
        assert_equal "unhealthy", result.details.dig(:jobs, :status)
        assert_equal "GoodJob table does not exist", result.details.dig(:jobs, :error)
      end
    end

    test "returns failure when background jobs check raises StandardError" do
      conn = ActiveRecord::Base.connection
      with_stub(conn, :table_exists?, ->(*) { raise StandardError, "Table check error" }) do
        result = Health::CheckService.call

        assert_not result.success?
        assert_equal :service_unavailable, result.error
        assert_includes result.message, "jobs"
        assert_equal "unhealthy", result.details.dig(:jobs, :status)
        assert_equal "Table check error", result.details.dig(:jobs, :error)
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
