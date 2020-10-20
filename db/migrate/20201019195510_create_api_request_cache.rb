class CreateApiRequestCache < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_request_caches do |t|
		t.integer :api_id
		t.string :url
		t.text :response
		t.timestamps
    end
  end
end
