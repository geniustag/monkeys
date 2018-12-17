class CreateEtransactions < ActiveRecord::Migration
  def change
    create_table :etransactions do |t|
      t.integer :player_id
      t.integer :address
      t.string :efrom
      t.string :eto
      t.string :amount
      t.string :key_price 
      t.text :extra_info
      t.string :token
      t.string :tx_hash
      t.integer :status
      t.text :event_data
      t.string :meth
      t.integer :parent_id
      t.integer :tran_type
      t.integer :block_number

      t.timestamps null: false
    end

    add_index :etransactions, :tx_hash, unique: true
    add_index :etransactions, :key_price, unique: true
    add_index :etransactions, :address
  end
end
