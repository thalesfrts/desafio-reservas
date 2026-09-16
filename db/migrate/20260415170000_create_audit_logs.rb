class CreateAuditLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :audit_logs do |t|
      t.references :actor, null: true, foreign_key: { to_table: :users }
      t.string :action, null: false
      t.references :auditable, polymorphic: true, null: true
      t.jsonb :context_data, null: false, default: {}
      t.jsonb :change_set, null: false, default: {}
      t.string :ip_address
      t.string :request_id
      t.text :user_agent

      t.timestamps
    end

    add_index :audit_logs, :action
    add_index :audit_logs, :created_at
  end
end
