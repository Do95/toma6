# Arma y envía un correo del historial. Si falla, reintenta (hasta 3 veces) y
# deja el error guardado para verlo en el panel.
class DeliverEmailJob < ApplicationJob
  queue_as :mailers

  MAX_ATTEMPTS = 3
  RETRY_WAITS = [2.minutes, 15.minutes].freeze

  discard_on ActiveRecord::RecordNotFound

  def perform(log_id)
    log = EmailLog.find_by(id: log_id)
    return if log.nil? || log.status == "sent"

    params = ActiveJob::Arguments.deserialize([log.params["params"] || {}]).first
    args = ActiveJob::Arguments.deserialize(log.params["args"] || [])
    delivery = log.mailer.constantize.with(params).public_send(log.action, *args)
    message = delivery.message

    if message.is_a?(ActionMailer::Base::NullMail) || Array(message.to).empty?
      return log.update!(status: "skipped", attempts: log.attempts + 1, last_attempt_at: Time.current,
                         error_message: "No se envió: la plantilla está desactivada o no hay destinatario configurado.")
    end

    message["X-Email-Log"] = log.id.to_s
    # Siempre queremos saber si falló, sin importar la configuración del entorno
    message.raise_delivery_errors = true
    log.update!(status: "sending", to: Array(message.to).join(", "), subject: message.subject,
                body_html: html_of(message), attempts: log.attempts + 1, last_attempt_at: Time.current)
    delivery.deliver_now
    log.update!(status: "sent", sent_at: Time.current, error_message: nil)
  rescue ActiveJob::DeserializationError
    log&.update_columns(status: "failed", error_message: "El registro relacionado ya no existe.")
  rescue StandardError => e
    handle_failure(log, e)
  end

  private

  def handle_failure(log, error)
    return unless log
    log.reload
    attempts = [log.attempts, 1].max
    message = "#{error.class}: #{error.message}".truncate(1000)
    if attempts < MAX_ATTEMPTS
      log.update_columns(status: "retrying", attempts: attempts, error_message: message, updated_at: Time.current)
      begin
        self.class.set(wait: RETRY_WAITS[attempts - 1] || 15.minutes).perform_later(log.id)
      rescue StandardError, NotImplementedError
        log.update_columns(status: "failed")
      end
    else
      log.update_columns(status: "failed", attempts: attempts, error_message: message, updated_at: Time.current)
    end
    Rails.logger.error("[DeliverEmailJob] Correo ##{log.id}: #{message}")
  end

  def html_of(message)
    part = message.html_part || (message.mime_type == "text/html" ? message : nil)
    part&.body&.decoded&.force_encoding("UTF-8")
  rescue StandardError
    nil
  end
end
