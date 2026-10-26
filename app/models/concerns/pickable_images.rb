# Fotos que se suben o se eligen de la galería (sin volver a subirlas).
# Por cada foto: la columna del archivo y <foto>_media_item_id. La que se eligió
# último es la que vale; «Quitar imagen» limpia las dos.
#
#   pickable_images :image, :image_secondary
#   record.photo_url(:image, :medium)  # subida, o la de la galería, o nil
module PickableImages
  extend ActiveSupport::Concern

  included do
    class_attribute :pickable_image_slots, default: []
  end

  class_methods do
    def pickable_images(*slots)
      self.pickable_image_slots = slots
      slots.each do |slot|
        mount_uploader slot, ImageUploader
        belongs_to :"#{slot}_media_item", class_name: "MediaItem", optional: true
      end
      before_validation :resolve_image_sources
      scope :with_photos, -> { includes(*slots.map { |slot| :"#{slot}_media_item" }) }
    end
  end

  # Foto subida o, si no hay, la elegida de la galería (si sigue existiendo)
  def photo_url(slot, version = :medium)
    uploader = public_send(slot)
    return uploader.url(version) if uploader.present?
    item = public_send(:"#{slot}_media_item")
    item.image_url(version) if item&.kept? && item[:image].present?
  end

  private

  def resolve_image_sources
    pickable_image_slots.each do |slot|
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
