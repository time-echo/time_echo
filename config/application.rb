require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TimeEcho
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.time_zone = "America/Bogota"
    config.active_job.queue_adapter = :good_job
    config.good_job.enable_cron = true
    config.good_job.cron = {
      cleanup_expired_tokens: {
        cron: "0 * * * *",
        class: "CleanupExpiredTokensJob"
      },
      dispatch_pending_letters: {
        cron: "0 0 * * *",
        class: "Letters::DispatchPendingJob"
      }
    }

    # Configure available locales and default locale
    config.i18n.available_locales = [ :es, :en ]
    config.i18n.default_locale = :en

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Rack middleware for rate-limiting requests and mitigating brute-force/DoS attacks
    config.middleware.use Rack::Attack

    # Handle exceptions raised outside controller dispatch (middleware, router)
    config.exceptions_app = ->(env) { Api::V1::ExceptionsController.action(:show).call(env) }

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
