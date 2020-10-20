class AddCachingToApiEndpoint < ActiveRecord::Migration[5.2]
  def change
	add_column :api_endpoints, :caching, :boolean, default: false
  end
end
