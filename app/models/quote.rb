class Quote < ApplicationRecord
  include Auditable
  include SoftDeletable

  STATUSES = {
    "draft" => "Borrador",
    "sent" => "Enviada",
    "accepted" => "Aceptada",
    "rejected" => "Rechazada",
    "expired" => "Vencida"
  }.freeze

  DISCOUNT_TYPES = { "percent" => "Porcentaje", "amount" => "Monto fijo" }.freeze

  belongs_to :quote_request, optional: true, inverse_of: :quote
  has_many :items, -> { order(:position, :id) }, class_name: "QuoteItem", inverse_of: :quote, dependent: :destroy

  accepts_nested_attributes_for :items, allow_destroy: true, reject_if: ->(a) { a[:description].blank? }

  validates :client_name, :issued_on, presence: true
  validates :client_email, format: { with: URI::MailTo::EMAIL_REGEXP }, allow_blank: true
  validates :status, inclusion: { in: STATUSES.keys }
  validates :discount_type, inclusion: { in: DISCOUNT_TYPES.keys }
  validates :discount_value, :tax_rate, numericality: { greater_than_or_equal_to: 0 }
  validate :at_least_one_item

  before_validation :assign_defaults, on: :create
  before_create :assign_number
  before_save :compute_totals
  before_save :capture_item_changes

  scope :recent, -> { order(issued_on: :desc, id: :desc) }

  def self.permission_resource = :sales

  # Número que tendrá la próxima cotización (solo para mostrar; el definitivo
  # se asigna al guardar, con bloqueo, para que nunca se repita).
  def self.next_number(settings = SiteSetting.current)
    transaction { DocumentNumber.next!(self, **numbering(settings)) }
  end

  def self.numbering(settings = SiteSetting.current)
    { prefix: settings.quote_prefix, with_year: settings.quote_number_year,
      digits: settings.quote_number_digits, start: settings.quote_number_start }
  end

  def status_label = STATUSES.fetch(status, status)
  def display_name = "#{number} · #{client_name}"
  def expired? = valid_until.present? && valid_until < Date.current && %w[draft sent].include?(status)

  def money(value) = "#{currency_symbol}#{ActiveSupport::NumberHelper.number_to_delimited(format('%.2f', value.to_d), delimiter: ',', separator: '.')}"

  def audit_extra_changes = @item_changes || {}

  def duplicate!
    copy = dup
    copy.assign_attributes(number: nil, token: nil, status: "draft", sent_at: nil, accepted_at: nil, rejected_at: nil,
                           issued_on: Date.current, valid_until: nil, quote_request_id: nil, created_by_id: nil, updated_by_id: nil)
    items.each { |i| copy.items.build(i.attributes.slice("service_id", "description", "details", "quantity", "unit_price", "position")) }
    copy.save!
    copy
  end

  private

  def assign_defaults
    settings = SiteSetting.current
    self.token = SecureRandom.urlsafe_base64(18) if token.blank?
    self.issued_on ||= Date.current
    self.valid_until ||= issued_on + settings.quote_validity_days.days
    self.currency_symbol = settings.currency_symbol if currency_symbol.blank?
  end

  # El número se asigna siempre automáticamente al crear (no se puede escribir a mano)
  def assign_number
    self.number = DocumentNumber.next!(self.class, **self.class.numbering)
  end

  def compute_totals
    live = items.reject(&:marked_for_destruction?)
    live.each(&:compute_total)
    self.subtotal = live.sum { |i| i.total.to_d }
    raw_discount = discount_type == "percent" ? subtotal * discount_value.to_d / 100 : discount_value.to_d
    self.discount_amount = [raw_discount, subtotal].min.round(2)
    taxable = subtotal - discount_amount
    self.tax_amount = (taxable * tax_rate.to_d / 100).round(2)
    self.total = (taxable + tax_amount).round(2)
  end

  def capture_item_changes
    return @item_changes = {} if new_record?
    added = items.select(&:new_record?).map(&:summary)
    removed = items.select(&:marked_for_destruction?).map(&:summary)
    edited = items.select { |i| i.persisted? && !i.marked_for_destruction? && i.changed? }.map(&:summary)
    out = {}
    out["ítems agregados"] = [nil, added.join(" | ")] if added.any?
    out["ítems quitados"] = [removed.join(" | "), nil] if removed.any?
    out["ítems editados"] = [nil, edited.join(" | ")] if edited.any?
    @item_changes = out
  end

  def at_least_one_item
    errors.add(:base, "Agregá al menos un ítem a la cotización.") if items.reject(&:marked_for_destruction?).empty?
  end
end
