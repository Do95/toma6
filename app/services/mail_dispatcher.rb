# Punto único para mandar correos. Registra el envío en el historial y lo
# encola; si algo falla queda anotado en el panel y nunca interrumpe a quien
# está usando el sitio.
#
#   MailDispatcher.deliver(QuoteRequestMailer, :confirm_client, { quote_request: req },
#                          record: req, template_key: "quote_request_client")
class MailDispatcher
  def self.deliver(mailer, action, params = {}, args: [], record: nil, template_key: nil)
    log = EmailLog.create!(
      mailer: mailer.name, action: action.to_s, template_key: template_key,
      params: { "params" => ActiveJob::Arguments.serialize([params]).first, "args" => ActiveJob::Arguments.serialize(args) },
      record: record, triggered_by: Current.user, status: "queued"
    )
    begin
      DeliverEmailJob.perform_later(log.id)
    rescue StandardError => e
      log.update_columns(status: "failed", error_message: "No se pudo poner en cola: #{e.class}: #{e.message}")
    end
    log
  rescue StandardError => e
    Rails.logger.error("[MailDispatcher] #{mailer}##{action}: #{e.class} #{e.message}")
    nil
  end
end
