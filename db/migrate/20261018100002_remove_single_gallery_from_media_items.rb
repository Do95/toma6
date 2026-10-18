# Las fotos ya no pertenecen a un solo álbum/proyecto: eso vive en media_placements.
class RemoveSingleGalleryFromMediaItems < ActiveRecord::Migration[8.0]
  def up
    remove_reference :media_items, :album, foreign_key: true, index: true
    remove_reference :media_items, :project, foreign_key: true, index: true
  end

  def down
    add_reference :media_items, :project, foreign_key: { on_delete: :cascade }
    add_reference :media_items, :album, foreign_key: { on_delete: :cascade }
    execute <<~SQL
      UPDATE media_items m SET album_id = p.album_id
      FROM (SELECT DISTINCT ON (media_item_id) media_item_id, album_id FROM media_placements WHERE album_id IS NOT NULL ORDER BY media_item_id, id) p
      WHERE m.id = p.media_item_id
    SQL
    execute <<~SQL
      UPDATE media_items m SET project_id = COALESCE(a.project_id, p.project_id)
      FROM media_placements p LEFT JOIN albums a ON a.id = p.album_id
      WHERE m.id = p.media_item_id
    SQL
  end
end
