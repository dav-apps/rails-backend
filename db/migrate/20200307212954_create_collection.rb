class CreateCollection < ActiveRecord::Migration[5.2]
  def change
	 create_table :collections do |t|
		t.integer :table_id
		t.string :name
		t.timestamps
    end
  end
end
