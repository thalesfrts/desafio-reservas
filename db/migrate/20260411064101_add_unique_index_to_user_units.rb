class AddUniqueIndexToUserUnits < ActiveRecord::Migration[7.2]
  def change
    add_index :user_units, [ :user_id, :unit_id ], unique: true
  end
end
