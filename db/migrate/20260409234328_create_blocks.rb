class CreateBlocks < ActiveRecord::Migration[7.2]
  def change
    create_table :blocks do |t|
      t.string :identification
      t.integer :floors_count
      t.integer :apartments_per_floor

      t.timestamps
    end
  end
end
