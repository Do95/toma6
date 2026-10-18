class User < ApplicationRecord
  include Auditable
  include SoftDeletable

  ROLES = {
    "admin" => "Administrador",
    "editor" => "Editor de contenido",
    "sales" => "Ventas",
    "viewer" => "Solo lectura"
  }.freeze

  ROLE_DESCRIPTIONS = {
    "admin" => "Acceso total: usuarios, ajustes, integraciones y papelera.",
    "editor" => "Gestiona el contenido del sitio, la galería y las publicaciones en redes.",
    "sales" => "Gestiona solicitudes y cotizaciones. Ve el contenido sin editarlo.",
    "viewer" => "Puede ver todo el panel, sin hacer cambios."
  }.freeze

  devise :database_authenticatable, :recoverable, :rememberable, :validatable, :trackable

  mount_uploader :avatar, AvatarUploader

  validates :name, presence: true
  validates :role, inclusion: { in: ROLES.keys }

  scope :ordered, -> { order(:name) }
  scope :active_accounts, -> { kept.where(active: true) }

  def self.permission_resource = :users

  def role_label = ROLES.fetch(role, role)
  def admin? = role == "admin"

  def initials
    name.to_s.split.first(2).map { |w| w[0] }.join.upcase.presence || email[0].upcase
  end

  # Devise: los usuarios desactivados o en la papelera no pueden entrar.
  def active_for_authentication? = super && active? && kept?
  def inactive_message = kept? && active? ? super : :account_disabled

  def can?(resource, action = :read) = Permissions.allowed?(self, resource, action)

  # Los correos de Devise (recuperar contraseña) pasan por el historial y se
  # envían en segundo plano: un error de correo nunca rompe la pantalla.
  def send_devise_notification(notification, *args)
    MailDispatcher.deliver(devise_mailer, notification, {}, args: [self, *args], record: self)
  end
end
