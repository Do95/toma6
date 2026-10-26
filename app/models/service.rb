class Service < ApplicationRecord
  include Auditable
  include SoftDeletable
  include Positionable
  include Publishable
  include FriendlySlug
  include PickableImages
  friendly_slug :title

  VISUAL_STYLES = {
    "video" => "Visor de cámara (1 foto)",
    "photo" => "Fotos impresas (3 fotos)",
    "edit" => "Línea de edición (1 foto)",
    "social" => "Pantallas de celular (3 fotos)",
    "podcast" => "Micrófono y ecualizador (sin fotos)",
    "image" => "Foto simple (1 foto)"
  }.freeze

  # Cada foto se sube o se elige de la galería
  pickable_images :image, :image_secondary, :image_tertiary

  has_many :options, -> { kept.ordered }, class_name: "ServiceOption", inverse_of: :service, dependent: :destroy
  has_many :all_options, class_name: "ServiceOption", dependent: :destroy
  has_and_belongs_to_many :projects
  has_and_belongs_to_many :plans

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
  # masked: sin precios en la página; solo 1 (tiene costo) o 0 (incluido), para no
  # dejar los montos en el código fuente cuando el cotizador no los muestra.
  def estimator_payload(masked: false)
    {
      id: id,
      title: title,
      base_price: masked ? (base_price.positive? ? 1 : 0) : base_price.to_f,
      price_unit: price_unit,
      options: visible_options.map { |o| o.estimator_payload(masked: masked) }
    }
  end
end
