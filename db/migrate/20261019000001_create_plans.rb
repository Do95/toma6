# Planes con precio cerrado para el cotizador. Cada plan puede cubrir servicios:
# en el cotizador esos servicios no suman su precio base, solo los extras que se agreguen.
class CreatePlans < ActiveRecord::Migration[8.0]
  def change
    create_table :plans do |t|
      t.string :title, null: false
      t.text :summary
      t.text :features                      # lo que incluye, una línea por punto
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.string :price_unit
      t.string :badge                       # "Más elegido"
      t.boolean :highlighted, null: false, default: false
      t.integer :position, null: false, default: 0
      t.boolean :published, null: false, default: true
      t.datetime :deleted_at, index: true
      t.references :created_by, :updated_by, :deleted_by, foreign_key: false
      t.timestamps
    end

    create_join_table :plans, :services do |t|
      t.index %i[plan_id service_id], unique: true
    end

    add_reference :quote_requests, :plan, foreign_key: false
  end
end
