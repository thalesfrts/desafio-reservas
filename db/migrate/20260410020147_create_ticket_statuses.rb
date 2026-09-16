class CreateTicketStatuses < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_statuses do |t|
      t.string :name
      t.boolean :is_default

      t.timestamps
    end
  end
end
