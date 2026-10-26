class User < ApplicationRecord
  include Auditable
  include SoftDeletable
  extend FriendlyId

  ROLES = {
    "admin" => "Administrador",
    "editor" => "Editor de contenido",
    "sales" => "Ventas",
    "viewer" => "Solo lectura"
  }.freeze

  ROLE_DESCRIPTIONS = {
    "admin" => "Acceso total: usuarios, ajustes, integraciones y papelera (restaurar). Eliminar definitivamente es solo del super admin.",
    "editor" => "Gestiona el contenido del sitio, la galería y las publicaciones en redes.",
    "sales" => "Gestiona solicitudes y cotizaciones. Ve el contenido sin editarlo.",
    "viewer" => "Puede ver todo el panel, sin hacer cambios."
  }.freeze

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  mount_uploader :avatar, AvatarUploader

  # La invitación es más larga que el enlace de recuperar contraseña (6 horas)
  INVITATION_VALID_FOR = 7.days

  belongs_to :invited_by, class_name: "User", optional: true

  # Código corto (ej. DM01): identifica quién creó cada cotización y va en la URL del panel
  friendly_id :code, use: :finders
  before_validation :normalize_code
  before_validation :assign_code, on: :create

  validates :name, presence: true
  validate :super_admin_stays_admin
  validates :code, presence: true, uniqueness: { case_sensitive: false },
                   format: { with: /\A[A-Z0-9]{2,8}\z/, message: "usa de 2 a 8 letras o números, sin espacios" }
  validates :role, inclusion: { in: ROLES.keys }

  scope :ordered, -> { order(:name) }
  scope :active_accounts, -> { kept.where(active: true) }

  def self.permission_resource = :users

  # Iniciales del nombre y un número: Donald Miranda → DM01 (DM02 si ya existe)
  def self.next_code_for(name)
    words = I18n.transliterate(name.to_s).upcase.scan(/[A-Z]+/)
    prefix = (words.size > 1 ? "#{words.first[0]}#{words.last[0]}" : words.first.to_s[0, 2]).ljust(2, "X")
    taken = unscoped.where("code LIKE ?", "#{prefix}%").pluck(:code).to_set
    (1..).lazy.map { |n| format("%s%02d", prefix, n) }.find { |code| taken.exclude?(code) }
  end

  def role_label = ROLES.fetch(role, role)
  def admin? = role == "admin"
  def role_display = super_admin? ? "Super admin" : role_label

  def initials
    name.to_s.split.first(2).map { |w| w[0] }.join.upcase.presence || email[0].upcase
  end

  # Devise: los usuarios desactivados o en la papelera no pueden entrar.
  def active_for_authentication? = super && active? && kept?
  def inactive_message = kept? && active? ? super : :account_disabled

  def can?(resource, action = :read) = Permissions.allowed?(self, resource, action)

  def invitation_pending? = invited_at.present? && invitation_accepted_at.nil?
  def invitation_expires_at = reset_password_sent_at && reset_password_sent_at + INVITATION_VALID_FOR
  def invitation_expired? = invitation_pending? && !reset_password_period_valid?

  # Manda (o reenvía) la invitación: un enlace para crear su contraseña y entrar.
  # Un enlace nuevo anula el anterior.
  def invite!(by:)
    update!(invited_at: Time.current, invited_by: by)
    send_devise_notification(:invitation_instructions, set_reset_password_token, {})
  end

  def accept_invitation!
    update_columns(invitation_accepted_at: Time.current) if invitation_pending?
  end

  # Devise: mientras la invitación está pendiente, el enlace dura 7 días
  def reset_password_period_valid?
    return super unless invitation_pending?
    reset_password_sent_at.present? && reset_password_sent_at >= INVITATION_VALID_FOR.ago
  end

  # Los correos de Devise (recuperar contraseña) pasan por el historial y se
  # envían en segundo plano: un error de correo nunca rompe la pantalla.
  def send_devise_notification(notification, *args)
    MailDispatcher.deliver(devise_mailer, notification, {}, args: [self, *args], record: self)
  end

  private

  # El super admin no puede perder el rol de administrador ni quedar desactivado
  def super_admin_stays_admin
    return unless super_admin?
    errors.add(:role, "del super admin tiene que ser Administrador") if role != "admin"
    errors.add(:active, "el super admin no se puede desactivar") unless active?
  end

  def normalize_code
    self.code = code.to_s.strip.upcase.presence
  end

  def assign_code
    self.code ||= self.class.next_code_for(name)
  end

  protected

  # Quien acepta la invitación recién crea su contraseña: no hace falta avisarle que «cambió»
  def send_password_change_notification? = super && !invitation_pending?
end
