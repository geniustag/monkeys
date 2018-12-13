class CreateGames < ActiveRecord::Migration
  def change
    create_table :games do |t|
      t.string :name
      t.string :core_address
      t.string :player_book_address
      t.string :actived_at
      t.text :extro

      t.timestamps
    end
  end
end
