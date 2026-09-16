class CreateTicketTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :ticket_types do |t|
      t.string :title
      t.integer :sla_hours

      t.timestamps
    end
  end
end
