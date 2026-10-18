class CreateEmailTemplatesAndLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :email_templates do |t|
      t.string :key, null: false
      t.string :name, null: false
      t.string :audience, null: false, default: "client"
      t.string :subject, null: false
      t.string :heading
      t.text :body, null: false
      t.string :button_label
      t.string :recipients
      t.boolean :enabled, null: false, default: true
      t.references :created_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.references :updated_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.timestamps
    end
    add_index :email_templates, :key, unique: true

    create_table :email_logs do |t|
      t.string :mailer, null: false
      t.string :action, null: false
      t.string :template_key
      t.jsonb :params, null: false, default: {}
      t.string :to
      t.string :subject
      t.string :status, null: false, default: "queued"
      t.integer :attempts, null: false, default: 0
      t.text :error_message
      t.text :body_html
      t.references :record, polymorphic: true
      t.references :triggered_by, foreign_key: { to_table: :users, on_delete: :nullify }
      t.datetime :sent_at
      t.datetime :last_attempt_at
      t.timestamps
    end
    add_index :email_logs, :status
    add_index :email_logs, :created_at
  end
end
