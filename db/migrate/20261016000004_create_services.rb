class CreateServices < ActiveRecord::Migration[8.0]
  def change
    create_table :services do |t|
      t.string :title, null: false
      t.string :slug, null: false
      t.text :summary
      t.text :description
      t.string :tags
      t.string :visual_style, null: false, default: "image"
      t.string :image
      t.string :image_secondary
      t.string :image_tertiary

      # Cotizador
      t.boolean :quotable, null: false, default: true
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0
      t.string :price_prefix, default: "Desde"
      t.string :price_unit

      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :services, :slug

    create_table :service_options do |t|
      t.references :service, null: false, foreign_key: { on_delete: :cascade }
      t.string :name, null: false
      t.text :description
      # addon: casilla con precio fijo · quantity: cantidad × precio · choice: una opción dentro de un grupo
      t.string :kind, null: false, default: "addon"
      t.string :group_name
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.string :unit_label
      t.integer :min_quantity, null: false, default: 0
      t.integer :max_quantity, null: false, default: 20
      t.boolean :default_selected, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
  end
end
