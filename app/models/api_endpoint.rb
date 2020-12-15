class ApiEndpoint < ApplicationRecord
	belongs_to :api
	has_many :api_endpoint_request_caches, class_name: "ApiEndpointRequestCache"
end