# Las fotos de un servicio pueden salir de la galería (sin volver a subirlas)
class AddGalleryPhotosToServices < ActiveRecord::Migration[8.0]
  def change
    add_reference :services, :image_media_item, foreign_key: { to_table: :media_items, on_delete: :nullify }
    add_reference :services, :image_secondary_media_item, foreign_key: { to_table: :media_items, on_delete: :nullify }
    add_reference :services, :image_tertiary_media_item, foreign_key: { to_table: :media_items, on_delete: :nullify }
  end
end
