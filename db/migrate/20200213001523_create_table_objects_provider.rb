class CreateTableObjectsProvider < ActiveRecord::Migration[5.2]
  def change
	 create_table :table_objects_providers do |t|
		t.integer :table_object_id
		t.integer :provider_id
    end
  end
end
