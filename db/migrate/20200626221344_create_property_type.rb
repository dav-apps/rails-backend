class CreatePropertyType < ActiveRecord::Migration[5.2]
  def change
	 create_table :property_types do |t|
		t.integer :table_id
		t.string :name
		t.integer :data_type, default: 0
    end
  end
end
