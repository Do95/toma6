# Historial de correos: cada envío queda registrado con su estado y su error,
# y se puede reintentar desde el panel. El cliente nunca ve estos errores.
class EmailLog < ApplicationRecord
  include RandomSlug

  STATUSES = {
    "queued" => "En cola", "sending" => "Enviando", "sent" => "Enviado",
    "retrying" => "Reintentando", "failed" => "Falló", "skipped" => "No enviado"
  }.freeze
  # Envíos automáticos por correo: el primero y un reintento. Después queda como «Falló».
  MAX_ATTEMPTS = 2

  belongs_to :record, polymorphic: true, optional: true
  belongs_to :triggered_by, class_name: "User", optional: true

  scope :recent, -> { order(created_at: :desc) }
  scope :failed, -> { where(status: "failed") }
  scope :pending, -> { where(status: %w[queued sending retrying]) }

  def self.permission_resource = :sales

  def status_label = STATUSES.fetch(status, status)
  def display_name = subject.presence || "#{mailer}##{action}"
  def retryable? = %w[failed skipped retrying].include?(status) && mailer != "Externo"
  # Se puede borrar del historial salvo mientras se está enviando
  def deletable? = status != "sending"

  def template = template_key && EmailTemplate.find_by(key: template_key)

  def retry!
    update!(status: "queued", error_message: nil, attempts: 0)
    DeliverEmailJob.perform_later(id)
  end
end
