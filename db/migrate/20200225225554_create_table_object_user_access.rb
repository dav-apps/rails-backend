class CreateTableObjectUserAccess < ActiveRecord::Migration[5.2]
  def change
	 create_table :table_object_user_accesses do |t|
		t.integer :table_object_id
		t.integer :user_id
		t.integer :table_alias
		t.timestamps
    end
  end
end
