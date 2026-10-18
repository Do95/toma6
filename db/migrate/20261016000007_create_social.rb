class CreateSocial < ActiveRecord::Migration[8.0]
  def change
    create_table :integrations do |t|
      t.string :provider, null: false
      t.string :app_id
      t.text :app_secret
      t.string :graph_version, null: false, default: "v23.0"
      t.text :user_access_token
      t.datetime :user_token_expires_at
      t.string :page_id
      t.string :page_name
      t.text :page_access_token
      t.string :instagram_account_id
      t.string :instagram_username
      t.boolean :facebook_enabled, null: false, default: false
      t.boolean :instagram_enabled, null: false, default: false
      t.datetime :connected_at
      t.references :connected_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.text :last_error
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :integrations, :provider, unique: true

    create_table :social_posts do |t|
      t.text :body
      t.string :link
      t.string :image
      t.references :media_item, foreign_key: { on_delete: :nullify }
      t.boolean :to_facebook, null: false, default: false
      t.boolean :to_instagram, null: false, default: false
      t.string :status, null: false, default: "draft"
      t.datetime :scheduled_at
      t.datetime :published_at
      t.string :facebook_post_id
      t.string :facebook_permalink
      t.string :instagram_media_id
      t.string :instagram_permalink
      t.text :error_message
      t.datetime :deleted_at, index: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :deleted_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :social_posts, [:status, :scheduled_at]
  end
end
