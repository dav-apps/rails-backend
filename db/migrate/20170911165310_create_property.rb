class CreateProperty < ActiveRecord::Migration
  def change
    create_table :properties do |t|
      t.integer :table_object_id
      t.string :name
      t.string :value
    end
  end
end
