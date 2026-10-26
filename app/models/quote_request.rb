class QuoteRequest < ApplicationRecord
  include Auditable
  extend FriendlyId
  friendly_id :number, use: :finders # /admin/solicitudes/SOL-2026-0001
  include SoftDeletable

  STATUSES = {
    "new" => "Nueva",
    "contacted" => "Contactada",
    "converted" => "Convertida en cotización",
    "discarded" => "Descartada"
  }.freeze

  has_one :quote, -> { kept }, inverse_of: :quote_request
  belongs_to :plan, optional: true

  normalizes :name, :message, :company, :location, :phone, with: ->(value) { value.to_s.strip.presence }
  normalizes :email, with: ->(value) { value.to_s.strip.downcase }

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :message, length: { maximum: 3000 }
  validates :phone, :company, :location, length: { maximum: 160 }
  validate :looks_like_a_person, on: :create
  validates :status, inclusion: { in: STATUSES.keys }
  validate :has_selections

  before_create :assign_number

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { kept.where(status: "new") }

  def self.permission_resource = :sales

  def status_label = STATUSES.fetch(status, status)
  def display_name = [number, name].compact.join(" · ")

  def selection_lines = Array(selections)

  # Línea del plan elegido (es la única sin servicio)
  def plan_line = selection_lines.find { |l| l["service_id"].blank? }

  # ¿Sumó servicios o extras con costo además del plan?
  def priced_extras? = selection_lines.any? { |l| l["service_id"].present? && l["total"].to_d.positive? }

  private

  def assign_number
    s = SiteSetting.current
    self.number = DocumentNumber.next!(self.class, prefix: s.request_prefix.presence || "SOL", with_year: true, digits: 4)
  end

  # Señales típicas de spam en el contenido (se le muestra el motivo a la persona)
  LINK = %r{https?://|www\.|\[url|<a\s}i
  MAX_LINKS = 2

  def looks_like_a_person
    errors.add(:name, "no puede incluir enlaces") if name.to_s.match?(LINK)
    errors.add(:company, "no puede incluir enlaces") if company.to_s.match?(LINK)
    errors.add(:message, "tiene demasiados enlaces (máximo #{MAX_LINKS})") if message.to_s.scan(%r{https?://|www\.}i).size > MAX_LINKS
    errors.add(:message, "no puede incluir código HTML ni BBCode") if message.to_s.match?(%r{<a\s|\[url|\[link}i)
  end

  def has_selections
    errors.add(:base, "Elegí un plan o al menos un servicio para cotizar.") if selection_lines.empty?
  end
end
