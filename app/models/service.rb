class Service < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable
  include FriendlySlug
  friendly_slug :title

  VISUAL_STYLES = {
    "video" => "Visor de cámara (1 foto)",
    "photo" => "Fotos impresas (3 fotos)",
    "edit" => "Línea de edición (1 foto)",
    "social" => "Pantallas de celular (3 fotos)",
    "podcast" => "Micrófono y ecualizador (sin fotos)",
    "image" => "Foto simple (1 foto)"
  }.freeze

  mount_uploader :image, ImageUploader
  mount_uploader :image_secondary, ImageUploader
  mount_uploader :image_tertiary, ImageUploader

  has_many :options, -> { kept.ordered }, class_name: "ServiceOption", inverse_of: :service, dependent: :destroy
  has_many :all_options, class_name: "ServiceOption", dependent: :destroy
  has_and_belongs_to_many :projects

  soft_delete_cascade :all_options

  accepts_nested_attributes_for :options, allow_destroy: true, reject_if: ->(a) { a[:name].blank? }

  validates :title, presence: true
  validates :visual_style, inclusion: { in: VISUAL_STYLES.keys }
  validates :base_price, numericality: { greater_than_or_equal_to: 0 }

  scope :quotable, -> { where(quotable: true) }

  def self.permission_resource = :content

  def tag_list = tags.to_s.split(",").map(&:strip).reject(&:blank?)

  def visible_options = options.select(&:published?)

  # Datos que usa el cotizador público (se recalcula en el servidor al enviar).
  def estimator_payload
    {
      id: id,
      title: title,
      base_price: base_price.to_f,
      price_unit: price_unit,
      options: visible_options.map(&:estimator_payload)
    }
  end
end
