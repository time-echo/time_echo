# frozen_string_literal: true

require "test_helper"

module Api
  module V1
    class SwaggerTest < ActionDispatch::IntegrationTest
      test "GET /api-docs renders Swagger UI" do
        get "/api-docs/index.html"

        assert_response :ok
        assert_includes response.body, "swagger-ui"
      end

      test "GET /api-docs/v1/swagger.yaml serves the valid OpenAPI 3.0 spec" do
        get "/api-docs/v1/swagger.yaml"

        assert_response :ok
        assert_includes response.body, "openapi: 3.0.3"
        assert_includes response.body, "TimeEcho API"
        assert_includes response.body, "/health/liveness"
        assert_includes response.body, "/health"
        assert_includes response.body, "/sessions"
        assert_includes response.body, "/letters"
        assert_includes response.body, "/account"
      end
    end
  end
end
