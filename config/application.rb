require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module TimeEcho
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1
    config.api_only = true
    config.time_zone = "America/Bogota"

    # Re-enable cookies and session store for session-based auth and GoodJob dashboard
    config.middleware.use ActionDispatch::Cookies
    config.middleware.use ActionDispatch::Session::CookieStore, key: "_time_echo_session"
    config.middleware.use ActionDispatch::Flash

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
  end
end
