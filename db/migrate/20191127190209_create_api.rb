class CreateApi < ActiveRecord::Migration[5.2]
  def change
	 create_table :apis do |t|
		t.integer :app_id
		t.string :name
    end
  end
end
