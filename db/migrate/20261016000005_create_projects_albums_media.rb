class CreateProjectsAlbumsMedia < ActiveRecord::Migration[8.0]
  def change
    create_table :projects do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.string :category_label
      t.string :client_name
      t.string :location
      t.date :event_date
      t.text :summary
      t.text :body
      t.string :cover
      t.string :video
      t.string :video_link
      t.boolean :featured, null: false, default: true
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :projects, :slug

    create_table :projects_services, id: false do |t|
      t.references :project, null: false, foreign_key: { on_delete: :cascade }
      t.references :service, null: false, foreign_key: { on_delete: :cascade }
    end
    add_index :projects_services, [:project_id, :service_id], unique: true

    create_table :albums do |t|
      t.references :project, foreign_key: { on_delete: :cascade }
      t.string :title, null: false
      t.string :slug, null: false
      t.text :description
      t.string :cover
      t.boolean :show_in_gallery, null: false, default: true
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :albums, :slug

    create_table :media_items do |t|
      t.references :project, foreign_key: { on_delete: :cascade }
      t.references :album, foreign_key: { on_delete: :cascade }
      t.references :category, foreign_key: { on_delete: :nullify }
      t.string :kind, null: false, default: "photo"
      t.string :image
      t.string :video
      t.string :title
      t.text :description
      t.integer :width
      t.integer :height
      t.string :duration
      t.boolean :show_in_gallery, null: false, default: true
      t.boolean :featured, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :media_items, [:show_in_gallery, :published]
  end
end
