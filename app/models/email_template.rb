# Plantillas de los correos automáticos. El texto admite variables como
# {{nombre}} y el mismo formato que el resto del panel (**negrita**, ==resaltado==).
class EmailTemplate < ApplicationRecord
  include Auditable

  COMMON_VARS = {
    "sitio" => "Nombre del sitio", "correo_sitio" => "Correo de contacto", "whatsapp" => "WhatsApp"
  }.freeze
  REQUEST_VARS = {
    "nombre" => "Nombre completo", "primer_nombre" => "Solo el primer nombre", "correo" => "Correo de la persona",
    "telefono" => "Teléfono", "empresa" => "Empresa", "fecha_evento" => "Fecha del evento", "lugar" => "Lugar",
    "mensaje" => "Lo que escribió", "servicios" => "Servicios elegidos", "total_estimado" => "Total estimado",
    "numero_solicitud" => "Código de la solicitud (SOL-…)"
  }.freeze
  QUOTE_VARS = {
    "nombre" => "Nombre del cliente", "primer_nombre" => "Solo el primer nombre", "numero" => "Número de cotización",
    "titulo" => "Título de la propuesta", "total" => "Total", "valida_hasta" => "Fecha de validez",
    "fecha_evento" => "Fecha del evento", "mensaje" => "Mensaje que escribís al enviarla"
  }.freeze

  DEFAULTS = {
    "quote_request_client" => {
      name: "Solicitud recibida (al cliente)", audience: "client", vars: REQUEST_VARS,
      subject: "Recibimos tu solicitud {{numero_solicitud}}, {{primer_nombre}}",
      heading: "¡Recibimos tu solicitud!",
      body: "Hola {{primer_nombre}}, gracias por escribirnos.\n\nTu solicitud es la **{{numero_solicitud}}**: guardá este código por si necesitás consultarnos.\n\nYa tenemos lo que armaste en el cotizador. En menos de 24 horas hábiles te respondemos con una **propuesta con precio cerrado**.\n\nEste es el resumen de lo que elegiste:",
      button_label: "Ver nuestros trabajos"
    },
    "quote_request_team" => {
      name: "Nueva solicitud (al equipo)", audience: "team", vars: REQUEST_VARS,
      subject: "Nueva solicitud {{numero_solicitud}} de {{nombre}} · {{total_estimado}}",
      heading: "Nueva solicitud de cotización",
      body: "**{{nombre}}** ({{correo}} · {{telefono}}) armó un estimado en el sitio.\n\nEvento: {{fecha_evento}} · {{lugar}}\n\nMensaje: {{mensaje}}",
      button_label: "Abrir en el panel"
    },
    "quote_sent_client" => {
      name: "Cotización enviada (al cliente)", audience: "client", vars: QUOTE_VARS,
      subject: "Tu cotización {{numero}} · {{sitio}}",
      heading: "Tu propuesta está lista",
      body: "Hola {{primer_nombre}},\n\n{{mensaje}}\n\nTe compartimos la cotización **{{numero}}** por **{{total}}**. Va adjunta en PDF y también podés verla y aceptarla en línea.\n\nEs válida hasta el {{valida_hasta}}.",
      button_label: "Ver y aceptar la cotización"
    },
    "quote_accepted_client" => {
      name: "Cotización aceptada (al cliente)", audience: "client", vars: QUOTE_VARS,
      subject: "¡Gracias por confirmar, {{primer_nombre}}!",
      heading: "¡Fecha reservada!",
      body: "Recibimos tu aceptación de la cotización **{{numero}}**.\n\nEn breve te escribimos para coordinar el anticipo y los detalles. ==Cada toma cuenta== y ya estamos pensando en la tuya.",
      button_label: "Ver la cotización"
    },
    "quote_accepted_team" => {
      name: "Cotización aceptada (al equipo)", audience: "team", vars: QUOTE_VARS,
      subject: "✓ {{nombre}} aceptó la cotización {{numero}}",
      heading: "¡Cotización aceptada!",
      body: "**{{nombre}}** aceptó la cotización **{{numero}}** por **{{total}}**.\n\nCoordiná el anticipo y la fecha.",
      button_label: "Abrir en el panel"
    }
  }.freeze

  validates :key, presence: true, uniqueness: true, inclusion: { in: DEFAULTS.keys }
  validates :name, :subject, :body, presence: true
  validate :recipients_are_emails

  def self.permission_resource = :settings

  def self.ensure_defaults!
    DEFAULTS.each do |key, d|
      next if exists?(key: key)
      create!(key: key, **d.except(:vars))
    end
  end

  def self.for(key)
    find_by(key: key) || create!(key: key, **DEFAULTS.fetch(key).except(:vars))
  end

  def display_name = name
  def team? = audience == "team"
  def variables = COMMON_VARS.merge(DEFAULTS.dig(key, :vars) || {})

  def recipient_list(fallback)
    list = recipients.to_s.split(/[,;\s]+/).reject(&:blank?)
    list.presence || Array(fallback).compact_blank
  end

  def restore_defaults!
    update!(DEFAULTS.fetch(key).except(:vars, :name, :audience))
  end

  # Devuelve el contenido listo para el correo con las variables reemplazadas.
  def render(vars)
    vars = vars.transform_keys(&:to_s)
    fill = ->(text) { text.to_s.gsub(/\{\{\s*(\w+)\s*\}\}/) { vars[$1].to_s } }
    body_text = fill.call(body).gsub(/\n{3,}/, "\n\n")
    {
      subject: fill.call(subject).squish,
      heading: fill.call(heading).squish.presence,
      body_html: ApplicationController.helpers.rich_text(body_text),
      button_label: fill.call(button_label).squish.presence
    }
  end

  private

  def recipients_are_emails
    bad = recipients.to_s.split(/[,;\s]+/).reject(&:blank?).reject { |e| e.match?(URI::MailTo::EMAIL_REGEXP) }
    errors.add(:recipients, "tiene direcciones no válidas: #{bad.join(', ')}") if bad.any?
  end
end
