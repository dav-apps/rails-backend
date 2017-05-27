class CreateDeck < ActiveRecord::Migration
  def change
    create_table :decks do |t|
      t.string :name
      t.integer :user_id
    end
  end
end
