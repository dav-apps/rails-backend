class CreateApiFunction < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_functions do |t|
		t.integer :api_id
		t.string :name
		t.string :params
		t.text :commands
    end
  end
end
