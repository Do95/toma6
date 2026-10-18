class AddCustomSections < ActiveRecord::Migration[8.0]
  def change
    change_table :sections, bulk: true do |t|
      t.string :illustration
      t.string :layout, null: false, default: "3"
      t.string :align, null: false, default: "left"
      t.string :block_style, null: false, default: "card"
      t.text :embed_code
      t.integer :embed_height, null: false, default: 450
    end

    # Columnas de las secciones personalizadas
    create_table :section_blocks do |t|
      t.references :section, null: false, foreign_key: { on_delete: :cascade }
      t.string :illustration
      t.string :image
      t.string :eyebrow
      t.string :title
      t.text :body
      t.string :button_label
      t.string :button_url
      t.integer :position, null: false, default: 0
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
