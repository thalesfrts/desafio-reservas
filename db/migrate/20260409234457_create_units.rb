class CreateUnits < ActiveRecord::Migration[7.2]
  def change
    create_table :units do |t|
      t.references :block, null: false, foreign_key: true
      t.string :identifier

      t.timestamps
    end
  end
end
