class CreateUserUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :user_units do |t|
      t.references :user, null: false, foreign_key: true
      t.references :unit, null: false, foreign_key: true

      t.timestamps
    end
  end
end
