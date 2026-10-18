# Enlaces cortos con QR: toma6.com/l/codigo redirige al destino y cuenta las visitas.
class CreateShortLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :short_links do |t|
      t.string :code, null: false
      t.string :title, null: false
      t.text :destination_url, null: false
      t.string :utm_source
      t.string :utm_medium
      t.string :utm_campaign
      t.datetime :expires_at
      t.boolean :active, null: false, default: true
      # Diseño del QR
      t.string :qr_style, null: false, default: "brand"
      t.boolean :qr_logo, null: false, default: true
      t.string :qr_label
      # Contadores (se actualizan con cada visita; el detalle está en short_link_clicks)
      t.integer :clicks_count, null: false, default: 0
      t.integer :qr_clicks_count, null: false, default: 0
      t.datetime :last_clicked_at
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :short_links, :code, unique: true

    # Una fila por visita. No se guarda la IP: solo una huella diaria anónima
    # para contar visitantes únicos.
    create_table :short_link_clicks do |t|
      t.references :short_link, null: false, foreign_key: { on_delete: :cascade }
      t.string :source, null: false, default: "link"
      t.string :device
      t.string :os
      t.string :browser
      t.string :referrer_host
      t.string :visitor_hash
      t.datetime :created_at, null: false
    end
    add_index :short_link_clicks, [:short_link_id, :created_at]
  end
end
