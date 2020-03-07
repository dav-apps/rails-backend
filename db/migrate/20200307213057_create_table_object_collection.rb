class CreateTableObjectCollection < ActiveRecord::Migration[5.2]
  def change
	 create_table :table_object_collections do |t|
		t.integer :table_object_id
		t.integer :collection_id
		t.timestamps
    end
  end
end
