class CreateReservations < ActiveRecord::Migration[7.2]
  def change
    create_table :reservations do |t|
      # O tipo 'references' com foreign_key: true cria automaticamente as colunas, os índices e as chaves estrangeiras (as setas do diagrama)
      t.references :user, null: false, foreign_key: true
      t.references :area, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      # O status 0 representará o estado "Solicitada" conforme a regra de negócio RN-01-04
      t.integer :status, default: 0, null: false
      t.text :denial_reason

      t.timestamps
    end
  end
end