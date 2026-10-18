# Una foto puede estar en varias galerías: álbumes y la galería general de
# cada proyecto. Cada galería tiene su propio orden.
# Copia la ubicación actual de cada foto, agrega la portada elegible del
# álbum y la huella (checksum) para no duplicar fotos al volver a subirlas.
class CreateMediaPlacements < ActiveRecord::Migration[8.0]
  def up
    create_table :media_placements do |t|
      t.references :media_item, null: false, foreign_key: { on_delete: :cascade }
      t.references :album, foreign_key: { on_delete: :cascade }
      t.references :project, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false, default: 0
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :media_placements, [:media_item_id, :album_id], unique: true, where: "album_id IS NOT NULL", name: "index_placements_unique_album"
    add_index :media_placements, [:media_item_id, :project_id], unique: true, where: "album_id IS NULL", name: "index_placements_unique_project"
    add_check_constraint :media_placements, "(album_id IS NOT NULL) <> (project_id IS NOT NULL)", name: "placement_one_gallery"

    add_reference :albums, :cover_media_item, foreign_key: { to_table: :media_items, on_delete: :nullify }
    add_column :media_items, :checksum, :string
    add_index :media_items, :checksum

    # Ubicación actual → galería
    execute <<~SQL
      INSERT INTO media_placements (media_item_id, album_id, project_id, position, created_at, updated_at)
      SELECT id, album_id, CASE WHEN album_id IS NULL THEN project_id END, position, NOW(), NOW()
      FROM media_items
      WHERE album_id IS NOT NULL OR project_id IS NOT NULL
    SQL
    # La huella (checksum) se calcula sobre el archivo original al subirlo, así
    # que aplica a las fotos que se suban desde ahora.
  end

  def down
    remove_column :media_items, :checksum
    remove_reference :albums, :cover_media_item
    drop_table :media_placements
  end
end
