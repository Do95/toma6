class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      ## Devise
      t.string :email, null: false, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.integer :sign_in_count, default: 0, null: false
      t.datetime :current_sign_in_at
      t.datetime :last_sign_in_at
      t.string :current_sign_in_ip
      t.string :last_sign_in_ip

      t.string :name, null: false
      t.string :role, null: false, default: "editor"
      t.string :avatar
      t.boolean :active, null: false, default: true

      t.datetime :deleted_at
      t.bigint :created_by_id
      t.bigint :updated_by_id
      t.bigint :deleted_by_id
      t.timestamps
    end

    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :deleted_at
    add_index :users, :role
    add_foreign_key :users, :users, column: :created_by_id, on_delete: :nullify
    add_foreign_key :users, :users, column: :updated_by_id, on_delete: :nullify
    add_foreign_key :users, :users, column: :deleted_by_id, on_delete: :nullify
  end
end
