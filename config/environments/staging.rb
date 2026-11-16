require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = false

  config.action_controller.perform_caching = true
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.logger   = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"

  config.active_support.report_deprecations = false
  config.cache_store = :memory_store
  config.active_job.queue_adapter = :good_job

  config.action_mailer.raise_delivery_errors = true
  config.action_mailer.default_url_options = { host: ENV.fetch("APP_HOST") { "localhost:3001" } }
  config.action_mailer.delivery_method = :resend

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [ :id ]

  config.active_record.encryption.primary_key = Rails.application.credentials[:primary_key]
  config.active_record.encryption.deterministic_key = Rails.application.credentials[:deterministic_key]
  config.active_record.encryption.key_derivation_salt = Rails.application.credentials[:key_derivation_salt]
end
