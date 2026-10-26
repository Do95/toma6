require_relative "../cache_store"
require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = true
  config.consider_all_requests_local = false
  config.action_controller.perform_caching = true

  config.public_file_server.enabled = ENV.fetch("RAILS_SERVE_STATIC_FILES", "true") == "true"
  config.public_file_server.headers = { "cache-control" => "public, max-age=#{1.year.to_i}" }

  config.assume_ssl = ENV.fetch("APP_PROTOCOL", "https") == "https"
  config.force_ssl = ENV.fetch("APP_PROTOCOL", "https") == "https"

  config.log_tags = [:request_id]
  config.logger = ActiveSupport::TaggedLogging.logger(STDOUT)
  config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
  config.silence_healthcheck_path = "/up"
  config.active_support.report_deprecations = false

  config.cache_store = CacheStoreConfig.store # Redis si está configurado (config/cache_store.rb)

  host = ENV.fetch("APP_HOST", "www.toma6.com")
  protocol = ENV.fetch("APP_PROTOCOL", "https")
  config.action_mailer.default_url_options = { host: host, protocol: protocol }
  config.action_mailer.asset_host = "#{protocol}://#{host}"
  config.action_mailer.delivery_method = :smtp
  config.action_mailer.smtp_settings = {
    address: ENV["SMTP_ADDRESS"],
    port: ENV.fetch("SMTP_PORT", 587).to_i,
    user_name: ENV["SMTP_USERNAME"],
    password: ENV["SMTP_PASSWORD"],
    authentication: :plain,
    enable_starttls_auto: true
  }

  config.i18n.fallbacks = true
  config.active_record.dump_schema_after_migration = false
  config.active_record.attributes_for_inspect = [:id]

  # Las tareas programadas corren dentro de Puma: un solo proceso que mantener.
  config.good_job.execution_mode = :async
end

