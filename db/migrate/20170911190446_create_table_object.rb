class CreateTableObject < ActiveRecord::Migration
  def change
    create_table :table_objects do |t|
      t.integer :table_id
      t.string :name
    end
  end
end
