class CreateActivityLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :activity_logs do |t|
      t.references :user, foreign_key: { on_delete: :nullify }
      t.string :user_name
      t.string :action, null: false
      t.string :subject_type
      t.bigint :subject_id
      t.string :subject_label
      t.jsonb :changeset, null: false, default: {}
      t.string :ip_address
      t.datetime :created_at, null: false
    end
    add_index :activity_logs, [:subject_type, :subject_id]
    add_index :activity_logs, :action
    add_index :activity_logs, :created_at
  end
end
