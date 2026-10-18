# Registra en el historial los correos que no pasan por MailDispatcher
# (por ejemplo, recuperar contraseña de Devise).
class EmailLogObserver
  def self.delivered_email(message)
    return if message["X-Email-Log"].present?
    EmailLog.create!(mailer: "Sistema", action: "devise", to: Array(message.to).join(", "),
                     subject: message.subject, status: "sent", sent_at: Time.current, attempts: 1,
                     body_html: (message.html_part || message).body.decoded.to_s.force_encoding("UTF-8"))
  rescue StandardError => e
    Rails.logger.warn("[EmailLogObserver] #{e.message}")
  end
end
