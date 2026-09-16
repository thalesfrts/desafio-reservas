class CreateTickets < ActiveRecord::Migration[7.2]
  def change
    create_table :tickets do |t|
      t.references :unit, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :ticket_type, null: false, foreign_key: true
      t.references :ticket_status, null: false, foreign_key: true
      t.text :description
      t.datetime :resolved_at

      t.timestamps
    end
  end
end
