class CreateKeys < ActiveRecord::Migration
  def change
    create_table :keys do |t|
      t.string :price
      t.integer :game_id
      t.integer :pid
      t.string :address

      t.timestamps
    end
  end
end
