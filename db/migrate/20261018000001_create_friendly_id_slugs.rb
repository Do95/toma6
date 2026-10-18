# Historial de slugs (friendly_id): si cambiás el título de un proyecto, la URL
# vieja redirige a la nueva. También registra los slugs actuales para que
# ninguna URL que ya esté compartida se rompa.
class CreateFriendlyIdSlugs < ActiveRecord::Migration[8.0]
  MODELS = { "Project" => "projects", "Album" => "albums", "Service" => "services", "Category" => "categories" }.freeze

  def up
    create_table :friendly_id_slugs do |t|
      t.string :slug, null: false
      t.integer :sluggable_id, null: false
      t.string :sluggable_type, limit: 50
      t.string :scope
      t.datetime :created_at
    end
    add_index :friendly_id_slugs, [:sluggable_type, :sluggable_id]
    add_index :friendly_id_slugs, [:slug, :sluggable_type], length: { slug: 140, sluggable_type: 50 }
    add_index :friendly_id_slugs, [:slug, :sluggable_type, :scope], length: { slug: 70, sluggable_type: 50, scope: 70 }, unique: true

    MODELS.each do |type, table|
      execute <<~SQL
        INSERT INTO friendly_id_slugs (slug, sluggable_id, sluggable_type, created_at)
        SELECT slug, id, '#{type}', NOW() FROM #{table} WHERE slug IS NOT NULL AND slug <> ''
      SQL
    end
  end

  def down
    drop_table :friendly_id_slugs
  end
end
