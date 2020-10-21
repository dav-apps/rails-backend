class CreateApiEndpointRequestCache < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_endpoint_request_caches do |t|
		t.integer :api_endpoint_id
		t.text :response
		t.timestamps
    end
  end
end
