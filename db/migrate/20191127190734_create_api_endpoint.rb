class CreateApiEndpoint < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_endpoints do |t|
		t.integer :api_id
		t.string :path
		t.string :method
		t.text :commands
    end
  end
end
