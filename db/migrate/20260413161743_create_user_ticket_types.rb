class CreateUserTicketTypes < ActiveRecord::Migration[7.2]
  def change
    create_table :user_ticket_types do |t|
      t.references :user, null: false, foreign_key: true
      t.references :ticket_type, null: false, foreign_key: true

      t.timestamps
    end
  end
end
