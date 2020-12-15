class Api < ApplicationRecord
	belongs_to :app
	has_many :api_errors
	has_many :api_endpoints
	has_many :api_functions
	has_many :api_env_vars
end