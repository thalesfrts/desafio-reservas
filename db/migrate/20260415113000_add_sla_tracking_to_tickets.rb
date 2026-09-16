class AddSlaTrackingToTickets < ActiveRecord::Migration[7.2]
  def up
    add_column :tickets, :sla_started_at, :datetime
    add_column :tickets, :sla_due_at, :datetime
    add_column :tickets, :sla_breached_at, :datetime
    add_column :tickets, :sla_cycle, :integer, default: 1, null: false

    add_index :tickets, :sla_due_at
    add_index :tickets, :sla_breached_at
    add_index :tickets, [ :ticket_status_id, :sla_due_at ]

    execute <<~SQL.squish
      UPDATE tickets
      SET
        sla_cycle = COALESCE(sla_cycle, 1),
        sla_started_at = COALESCE(sla_started_at, tickets.created_at),
        sla_due_at = COALESCE(
          sla_due_at,
          tickets.created_at + (COALESCE(ticket_types.sla_hours, 0) || ' hours')::interval
        ),
        sla_breached_at = CASE
          WHEN tickets.resolved_at IS NOT NULL
               AND tickets.resolved_at > (tickets.created_at + (COALESCE(ticket_types.sla_hours, 0) || ' hours')::interval)
            THEN tickets.resolved_at
          WHEN tickets.resolved_at IS NULL
               AND NOW() > (tickets.created_at + (COALESCE(ticket_types.sla_hours, 0) || ' hours')::interval)
            THEN NOW()
          ELSE tickets.sla_breached_at
        END
      FROM ticket_types
      WHERE ticket_types.id = tickets.ticket_type_id
    SQL
  end

  def down
    remove_index :tickets, [ :ticket_status_id, :sla_due_at ]
    remove_index :tickets, :sla_breached_at
    remove_index :tickets, :sla_due_at

    remove_column :tickets, :sla_cycle
    remove_column :tickets, :sla_breached_at
    remove_column :tickets, :sla_due_at
    remove_column :tickets, :sla_started_at
  end
end
