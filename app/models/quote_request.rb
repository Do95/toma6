class QuoteRequest < ApplicationRecord
  include Auditable
  include SoftDeletable

  STATUSES = {
    "new" => "Nueva",
    "contacted" => "Contactada",
    "converted" => "Convertida en cotización",
    "discarded" => "Descartada"
  }.freeze

  has_one :quote, -> { kept }, inverse_of: :quote_request

  validates :name, presence: true, length: { maximum: 120 }
  validates :email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :status, inclusion: { in: STATUSES.keys }
  validate :has_selections

  before_create :assign_number

  scope :recent, -> { order(created_at: :desc) }
  scope :pending, -> { kept.where(status: "new") }

  def self.permission_resource = :sales

  def status_label = STATUSES.fetch(status, status)
  def display_name = [number, name].compact.join(" · ")

  def selection_lines = Array(selections)

  private

  def assign_number
    s = SiteSetting.current
    self.number = DocumentNumber.next!(self.class, prefix: s.request_prefix.presence || "SOL", with_year: true, digits: 4)
  end

  def has_selections
    errors.add(:base, "Elegí al menos un servicio para cotizar.") if selection_lines.empty?
  end
end
