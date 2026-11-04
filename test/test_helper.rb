require "simplecov"
SimpleCov.start "rails"

ENV["RAILS_ENV"] ||= "test"

require_relative "../config/environment"
require "rails/test_help"

module ActiveSupport
  class TestCase
    parallelize(workers: 1) unless Gem.win_platform?

    setup { I18n.locale = :es }

    if defined?(Bullet) && Bullet.enable?
      setup do
        Bullet.start_request
      end

      teardown do
        Bullet.perform_out_of_channel_notifications if Bullet.notification?
        Bullet.end_request
      end
    end

    fixtures :all
  end
end

require_relative "support/api_response_assertions"

class ActionDispatch::IntegrationTest
  include ApiResponseAssertions
end
