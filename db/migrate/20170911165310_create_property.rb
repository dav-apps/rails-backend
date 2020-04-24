class CreateProperty < ActiveRecord::Migration[4.2]
  def change
    create_table :properties do |t|
      t.integer :table_object_id
      t.string :name
      t.string :value
    end
  end
end
