# Plantillas de los correos automáticos. El texto admite variables como
# {{nombre}} y el mismo formato que el resto del panel (**negrita**, ==resaltado==).
class EmailTemplate < ApplicationRecord
  include Auditable
  extend FriendlyId
  friendly_id :key, use: :finders
  include PickableImages

  # Foto de portada: subida, elegida de la galería o la predeterminada (hero_asset,
  # en app/assets/images/mail). Sin ninguna, el correo va sin portada.
  pickable_images :hero_image
  before_validation :drop_default_hero

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
  ACCOUNT_VARS = {
    "nombre" => "Nombre de la persona", "primer_nombre" => "Solo el primer nombre", "correo" => "Correo de la cuenta",
    "rol" => "Rol en el panel", "invitado_por" => "Quién la invitó", "vence" => "Hasta cuándo sirve el enlace"
  }.freeze

  DEFAULTS = {
    "quote_request_client" => {
      name: "Solicitud recibida (al cliente)", audience: "client", vars: REQUEST_VARS, hero_asset: "mail/hero-solicitud.jpg",
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
      name: "Cotización enviada (al cliente)", audience: "client", vars: QUOTE_VARS, hero_asset: "mail/hero-propuesta.jpg",
      subject: "Tu cotización {{numero}} · {{sitio}}",
      heading: "Tu propuesta está lista",
      body: "Hola {{primer_nombre}},\n\n{{mensaje}}\n\nTe compartimos la cotización **{{numero}}** por **{{total}}**. Va adjunta en PDF y también podés verla y aceptarla en línea.\n\nEs válida hasta el {{valida_hasta}}.",
      button_label: "Ver y aceptar la cotización"
    },
    "quote_accepted_client" => {
      name: "Cotización aceptada (al cliente)", audience: "client", vars: QUOTE_VARS, hero_asset: "mail/hero-confirmada.jpg",
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
    },
    "user_invitation" => {
      name: "Invitación al panel", audience: "account", vars: ACCOUNT_VARS, hero_asset: "mail/hero-bienvenida.jpg",
      subject: "{{invitado_por}} te invitó al panel de {{sitio}}",
      heading: "Te sumamos al equipo",
      body: "Hola {{primer_nombre}},\n\n**{{invitado_por}}** te invitó a administrar el sitio de **{{sitio}}** como **{{rol}}**.\n\nPara entrar, creá tu contraseña con el botón de abajo. Vas a ingresar siempre con este correo: {{correo}}.\n\nEl enlace sirve hasta el {{vence}}. Si vence, pedile a quien te invitó que te lo reenvíe.",
      button_label: "Crear mi contraseña"
    },
    "password_reset" => {
      name: "Recuperar contraseña", audience: "account", vars: ACCOUNT_VARS,
      subject: "Creá una contraseña nueva para {{sitio}}",
      heading: "Recuperar contraseña",
      body: "Hola {{primer_nombre}},\n\nRecibimos un pedido para crear una contraseña nueva para tu cuenta del panel de {{sitio}}.\n\nEl enlace sirve hasta el {{vence}}. Si no lo pediste, ignorá este correo: tu contraseña no cambia.",
      button_label: "Crear contraseña nueva"
    },
    "password_changed" => {
      name: "Contraseña cambiada", audience: "account", vars: ACCOUNT_VARS,
      subject: "Tu contraseña de {{sitio}} cambió",
      heading: "Tu contraseña cambió",
      body: "Hola {{primer_nombre}},\n\nTe avisamos que la contraseña de tu cuenta del panel de {{sitio}} acaba de cambiar.\n\n==¿No fuiste vos?== Recuperá el acceso con el botón de abajo y avisale a un administrador.",
      button_label: "Recuperar el acceso"
    },
    "email_changed" => {
      name: "Correo de la cuenta cambiado", audience: "account", vars: ACCOUNT_VARS,
      subject: "El correo de tu cuenta de {{sitio}} cambió",
      heading: "Tu correo de ingreso cambió",
      body: "Hola {{primer_nombre}},\n\nTe avisamos que la cuenta del panel de {{sitio}} ahora ingresa con **{{correo}}**. Este correo ya no sirve para entrar.\n\n==¿No fuiste vos?== Avisale a un administrador cuanto antes.",
      button_label: nil
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
  # Correos de la cuenta (invitación, contraseña): se envían siempre, no se pueden desactivar
  def account? = audience == "account"
  def variables = COMMON_VARS.merge(DEFAULTS.dig(key, :vars) || {})

  def recipient_list(fallback)
    list = recipients.to_s.split(/[,;\s]+/).reject(&:blank?)
    list.presence || Array(fallback).compact_blank
  end

  # Vuelve al texto y a la portada originales
  def restore_defaults!
    transaction do
      update!(DEFAULTS.fetch(key).except(:vars, :name, :audience, :hero_asset)
                .merge(remove_hero_image: hero_image.present?, hero_image_media_item_id: nil))
      update_columns(hero_asset: DEFAULTS.dig(key, :hero_asset))
    end
  end

  def default_hero? = DEFAULTS.dig(key, :hero_asset).present?

  # Devuelve el contenido listo para el correo con las variables reemplazadas.
  def render(vars)
    vars = vars.transform_keys(&:to_s)
    fill = ->(text) { text.to_s.gsub(/\{\{\s*(\w+)\s*\}\}/) { vars[$1].to_s } }
    # Una variable vacía dentro de **…** o ==…== no debe romper el formato del resto del texto
    body_text = fill.call(body).gsub(/\*\*\s*\*\*|==\s*==/, "").gsub(/\n{3,}/, "\n\n")
    {
      subject: fill.call(subject).squish,
      heading: fill.call(heading).squish.presence,
      body_html: ApplicationController.helpers.rich_text(body_text),
      button_label: fill.call(button_label).squish.presence
    }
  end

  private

  # Si se sube, se elige o se quita una foto, la predeterminada deja de usarse
  def drop_default_hero
    changed_hero = remove_hero_image? || will_save_change_to_hero_image? || will_save_change_to_hero_image_media_item_id?
    self.hero_asset = nil if changed_hero && persisted?
  end

  def recipients_are_emails
    bad = recipients.to_s.split(/[,;\s]+/).reject(&:blank?).reject { |e| e.match?(URI::MailTo::EMAIL_REGEXP) }
    errors.add(:recipients, "tiene direcciones no válidas: #{bad.join(', ')}") if bad.any?
  end
end
