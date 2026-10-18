class CreateSections < ActiveRecord::Migration[8.0]
  def change
    create_table :sections do |t|
      # Página a la que pertenece: el inicio ("home") o un proyecto
      t.string :page, null: false, default: "home"
      t.references :project, foreign_key: { on_delete: :cascade }
      t.string :kind, null: false
      t.string :anchor
      t.string :eyebrow
      t.string :title
      t.text :lead
      t.text :body
      t.text :note
      t.text :items
      t.string :image
      t.string :image_side, null: false, default: "right"
      t.string :video
      t.string :video_link
      t.string :button_label
      t.string :button_url
      t.string :secondary_label
      t.string :secondary_url
      t.string :theme, null: false, default: "dark"
      t.references :album, foreign_key: { on_delete: :nullify }
      t.boolean :show_in_nav, null: false, default: false
      t.string :nav_label
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :sections, [:page, :project_id, :position]
  end
end
