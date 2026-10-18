# Numeración automática configurable para cotizaciones y solicitudes.
class AddDocumentNumbering < ActiveRecord::Migration[8.0]
  def up
    change_table :site_settings, bulk: true do |t|
      t.boolean :quote_number_year, null: false, default: true   # COT-2026-0001 o COT-0001
      t.integer :quote_number_digits, null: false, default: 4
      t.integer :quote_number_start, null: false, default: 1     # para continuar una numeración anterior
      t.string :request_prefix, null: false, default: "SOL"
    end

    add_column :quote_requests, :number, :string
    # Código para las solicitudes que ya existen, en orden de llegada y por año
    execute <<~SQL
      UPDATE quote_requests q SET number = 'SOL-' || EXTRACT(YEAR FROM q.created_at)::int || '-' || LPAD(n.seq::text, 4, '0')
      FROM (
        SELECT id, ROW_NUMBER() OVER (PARTITION BY EXTRACT(YEAR FROM created_at) ORDER BY created_at, id) AS seq
        FROM quote_requests
      ) n
      WHERE q.id = n.id
    SQL
    add_index :quote_requests, :number, unique: true
  end

  def down
    remove_index :quote_requests, :number
    remove_column :quote_requests, :number
    change_table :site_settings, bulk: true do |t|
      t.remove :quote_number_year, :quote_number_digits, :quote_number_start, :request_prefix
    end
  end
end
