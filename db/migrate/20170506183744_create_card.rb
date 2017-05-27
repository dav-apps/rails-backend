class CreateCard < ActiveRecord::Migration
  def change
    create_table :cards do |t|
      t.string :page1
      t.string :page2
      t.integer :deck_id
    end
  end
end
