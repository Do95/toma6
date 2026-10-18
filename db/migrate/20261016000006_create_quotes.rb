class CreateQuotes < ActiveRecord::Migration[8.0]
  def change
    create_table :quote_requests do |t|
      t.string :name, null: false
      t.string :email, null: false
      t.string :phone
      t.string :company
      t.date :event_date
      t.string :location
      t.text :message
      t.jsonb :selections, null: false, default: []
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :estimated_total, precision: 12, scale: 2, null: false, default: 0
      t.string :status, null: false, default: "new"
      t.string :ip_address
      t.string :user_agent
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :quote_requests, :status

    create_table :quotes do |t|
      t.string :number, null: false
      t.string :token, null: false
      t.string :status, null: false, default: "draft"
      t.string :title
      t.string :client_name, null: false
      t.string :client_company
      t.string :client_email
      t.string :client_phone
      t.string :client_tax_id
      t.date :event_date
      t.string :event_location
      t.date :issued_on, null: false
      t.date :valid_until
      t.string :currency_symbol, null: false, default: "$"
      t.string :discount_type, null: false, default: "percent"
      t.decimal :discount_value, precision: 12, scale: 2, null: false, default: 0
      t.string :tax_name, null: false, default: "IVA"
      t.decimal :tax_rate, precision: 5, scale: 2, null: false, default: 0
      t.decimal :subtotal, precision: 12, scale: 2, null: false, default: 0
      t.decimal :discount_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :tax_amount, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.text :notes
      t.text :terms
      t.text :payment_info
      t.references :quote_request, foreign_key: { on_delete: :nullify }
      t.datetime :sent_at
      t.datetime :accepted_at
      t.datetime :rejected_at
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :quotes, :number, unique: true
    add_index :quotes, :token, unique: true
    add_index :quotes, :status

    create_table :quote_items do |t|
      t.references :quote, null: false, foreign_key: { on_delete: :cascade }
      t.references :service, foreign_key: { on_delete: :nullify }
      t.string :description, null: false
      t.text :details
      t.decimal :quantity, precision: 10, scale: 2, null: false, default: 1
      t.decimal :unit_price, precision: 12, scale: 2, null: false, default: 0
      t.decimal :total, precision: 12, scale: 2, null: false, default: 0
      t.integer :position, null: false, default: 0
      t.timestamps
    end
  end
end
