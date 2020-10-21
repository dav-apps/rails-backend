class Api < ApplicationRecord
	belongs_to :app
	has_many :api_errors, dependent: :destroy
	has_many :api_endpoints, dependent: :destroy
	has_many :api_functions, dependent: :destroy
	has_many :api_env_vars, dependent: :destroy
end