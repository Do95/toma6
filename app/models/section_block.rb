# Columna de una sección personalizada.
class SectionBlock < ApplicationRecord
  include BustsSiteCache
  include Auditable
  include SoftDeletable
  include Positionable

  mount_uploader :image, ImageUploader
  belongs_to :section, inverse_of: :blocks

  validates :illustration, inclusion: { in: ->(_) { Illustrations.keys + ["none"] } }, allow_blank: true
  validates :button_url, format: { with: %r{\A(https?://|/|#|mailto:|tel:)}i, message: "debe empezar con https://, / o #" }, allow_blank: true

  # Quitar una columna desde el formulario la manda a la papelera
  attr_reader :remove

  def remove=(value)
    @remove = value
    return unless ActiveModel::Type::Boolean.new.cast(value)
    self.deleted_at ||= Time.current
    self.deleted_by_id = Current.user&.id
  end

  def self.permission_resource = :content
  def display_name = title.presence || "Columna de «#{section&.display_name}»"

  def illustration_key
    key = illustration.presence
    key && key != "none" && Illustrations.exists?(key) ? key : nil
  end
end
