class CreateApp < ActiveRecord::Migration
  def change
    create_table :apps do |t|
      t.string :name
      t.text :description
      t.integer :dev_id
      t.boolean :published, default: false
      t.timestamps
    end
  end
end
