class CreateTableObject < ActiveRecord::Migration[4.2]
  def change
    create_table :table_objects do |t|
      t.integer :table_id
      t.timestamps
    end
  end
end
