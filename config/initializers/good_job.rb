# Tareas programadas.
# - Purga de papelera: todos los días a las 3:00 borra definitivamente lo que lleva
#   más días en la papelera que lo configurado en Ajustes (15 por defecto).
# - Publicaciones programadas: revisa cada 5 minutos si hay posts para publicar.
Rails.application.configure do
  # Desactivado (JOBS_ENABLED distinto de "true"): GoodJob no arranca en el
  # proceso web (ni notificador, ni cron, ni hilos).
  unless config.x.jobs_enabled
    config.good_job.execution_mode = :external
    config.good_job.enable_cron = false
    config.good_job.enable_listen_notify = false
    next
  end

  config.good_job.enable_cron = true
  config.good_job.max_threads = 3
  config.good_job.poll_interval = 30
  config.good_job.shutdown_timeout = 25
  config.good_job.preserve_job_records = true
  config.good_job.cleanup_preserved_jobs_before_seconds_ago = 14.days.to_i
  config.good_job.cron = {
    purge_trash: {
      cron: "0 3 * * *",
      class: "PurgeTrashJob",
      description: "Borra definitivamente los registros que superaron los días de retención en la papelera"
    },
    scheduled_social_posts: {
      cron: "*/5 * * * *",
      class: "DispatchScheduledPostsJob",
      description: "Publica en Facebook/Instagram los posts programados"
    }
  }
end
