class ApiEndpointRequestCache < ApplicationRecord
	belongs_to :api_endpoint
	has_many :api_endpoint_request_cache_params, dependent: :destroy
end