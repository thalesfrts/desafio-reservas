class ImproveTicketStatuses < ActiveRecord::Migration[7.2]
  def up
    add_column :ticket_statuses, :is_final, :boolean, default: false, null: false

    execute "UPDATE ticket_statuses SET is_default = FALSE WHERE is_default IS NULL"
    change_column_default :ticket_statuses, :is_default, from: nil, to: false
    change_column_null :ticket_statuses, :is_default, false

    add_index :ticket_statuses,
              :is_default,
              unique: true,
              where: "is_default",
              name: "index_ticket_statuses_on_is_default_true"
  end

  def down
    remove_index :ticket_statuses, name: "index_ticket_statuses_on_is_default_true"
    change_column_null :ticket_statuses, :is_default, true
    change_column_default :ticket_statuses, :is_default, from: false, to: nil
    remove_column :ticket_statuses, :is_final
  end
end
