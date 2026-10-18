require "active_support/core_ext/integer/time"

Rails.application.configure do
  config.enable_reloading = true
  # Detecta cambios de código revisando las fechas de los archivos (sin la gema
  # listen). Más estable en macOS, sobre todo con carpetas sincronizadas con iCloud.
  config.file_watcher = ActiveSupport::FileUpdateChecker
  config.eager_load = false
  config.consider_all_requests_local = true
  config.server_timing = true

  if Rails.root.join("tmp/caching-dev.txt").exist?
    config.action_controller.perform_caching = true
    config.cache_store = :memory_store
  else
    config.action_controller.perform_caching = false
    config.cache_store = :null_store
  end

  config.action_mailer.raise_delivery_errors = true # los errores quedan en Panel → Correos
  config.action_mailer.perform_caching = false
  config.action_mailer.delivery_method = :letter_opener
  config.action_mailer.default_url_options = { host: "localhost", port: 3000 }

  config.active_support.deprecation = :log
  config.active_record.migration_error = :page_load
  config.active_record.verbose_query_logs = true
  config.active_job.verbose_enqueue_logs = true

  config.action_view.annotate_rendered_view_with_filenames = true
  config.action_controller.raise_on_missing_callback_actions = true

  # Las tareas corren dentro del servidor web (no hace falta un proceso aparte)
  config.good_job.execution_mode = :async
end
