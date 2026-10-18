require_relative "boot"

require "rails"
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

Bundler.require(*Rails.groups)

module Toma6
  class Application < Rails::Application
    config.load_defaults 8.0
    config.autoload_lib(ignore: %w[assets tasks])

    config.time_zone = ENV.fetch("APP_TIME_ZONE", "America/El_Salvador")
    config.i18n.default_locale = :es
    config.i18n.available_locales = [:es]

    # Tareas en segundo plano.
    #   JOBS_ENABLED=true  → GoodJob (cola en la base de datos, reintentos y tareas programadas)
    #   sin definir/false  → adaptador :async de Rails (en memoria, dentro del mismo proceso).
    #                        Sin cron: la purga de la papelera y las publicaciones
    #                        programadas se corren con las tareas rake (ver README).
    config.x.jobs_enabled = ENV.fetch("JOBS_ENABLED", "false") == "true"
    config.active_job.queue_adapter = config.x.jobs_enabled ? :good_job : :async

    # Cifrado de tokens de integraciones (Facebook / Instagram).
    # En producción definí estas tres variables (generalas con: bin/rails db:encryption:init).
    config.active_record.encryption.primary_key = ENV.fetch("AR_ENCRYPTION_PRIMARY_KEY", "dev-only-primary-key-change-me-0001")
    config.active_record.encryption.deterministic_key = ENV.fetch("AR_ENCRYPTION_DETERMINISTIC_KEY", "dev-only-deterministic-key-0001")
    config.active_record.encryption.key_derivation_salt = ENV.fetch("AR_ENCRYPTION_KEY_DERIVATION_SALT", "dev-only-key-derivation-salt-0001")

    config.generators do |g|
      g.helper false
      g.assets false
      g.test_framework nil
    end
  end
end
