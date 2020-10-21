class CreateApiEndpointRequestCacheParam < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_endpoint_request_cache_params do |t|
		t.integer :api_endpoint_request_cache_id
		t.string :name
		t.string :value
    end
  end
end
