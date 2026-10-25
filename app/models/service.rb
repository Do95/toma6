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

  # Cada foto se sube o se elige de la galería; la que se eligió último es la que vale.
  IMAGE_SLOTS = %i[image image_secondary image_tertiary].freeze
  IMAGE_SLOTS.each do |slot|
    belongs_to :"#{slot}_media_item", class_name: "MediaItem", optional: true
  end
  before_validation :resolve_image_sources

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
  scope :with_photos, -> { includes(*IMAGE_SLOTS.map { |slot| :"#{slot}_media_item" }) }

  def self.permission_resource = :content

  def tag_list = tags.to_s.split(",").map(&:strip).reject(&:blank?)

  def visible_options = options.select(&:published?)

  # Foto subida o, si no hay, la elegida de la galería (si sigue existiendo)
  def photo_url(slot, version = :medium)
    uploader = public_send(slot)
    return uploader.url(version) if uploader.present?
    item = public_send(:"#{slot}_media_item")
    item.image_url(version) if item&.kept? && item[:image].present?
  end

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

  private

  def resolve_image_sources
    IMAGE_SLOTS.each do |slot|
      ref = :"#{slot}_media_item_id"
      if public_send(:"remove_#{slot}?")
        self[ref] = nil
      elsif will_save_change_to_attribute?(slot) && public_send(slot).present?
        self[ref] = nil # se subió una foto nueva: reemplaza a la de la galería
      elsif will_save_change_to_attribute?(ref) && self[ref].present? && self[slot].present?
        public_send(:"remove_#{slot}=", true) # se eligió de la galería: se quita la subida
      end
    end
  end
end
