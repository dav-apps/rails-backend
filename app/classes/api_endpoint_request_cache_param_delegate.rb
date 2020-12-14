class ApiEndpointRequestCacheParamDelegate
	attr_reader :api_endpoint_request_cache_param
	attr_accessor :id, :api_endpoint_request_cache_id, :name, :value

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@api_endpoint_request_cache_id = attributes[:api_endpoint_request_cache_id]
		@name = attributes[:name]
		@value = attributes[:value]

		@api_endpoint_request_cache_param = ApiEndpointRequestCacheParamMigration.find_by(id: @id)
		@api_endpoint_request_cache_param = ApiEndpointRequestCacheParamMigration.new(id: @id) if @api_endpoint_request_cache_param.nil?
	end

	def attributes
		{
			id: @id,
			api_endpoint_request_cache_id: @api_endpoint_request_cache_id,
			name: @name,
			value: @value
		}
	end

	def save
		# Copy the values to the api_endpoint_request_cache_param
		@api_endpoint_request_cache_param.api_endpoint_request_cache_id = @api_endpoint_request_cache_id
		@api_endpoint_request_cache_param.name = @name
		@api_endpoint_request_cache_param.value = @value
		delete_old = false

		# Check the id
		if @api_endpoint_request_cache_param.id.nil?
			# Get the ids for the last api_endpoint_request_cache_param in the old and new database
			last_param = ApiEndpointRequestCacheParam.last
			last_param_migration = ApiEndpointRequestCacheParamMigration.last

			if !last_param.nil? && !last_param_migration.nil?
				if last_param.id >= last_param_migration.id
					@api_endpoint_request_cache_param.id = last_param.id + 1
				else
					@api_endpoint_request_cache_param.id = last_param_migration.id + 1
				end
			elsif !last_param.nil?
				@api_endpoint_request_cache_param.id = last_param.id + 1
			elsif !last_param_migration.nil?
				@api_endpoint_request_cache_param.id = last_param_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api_endpoint_request_cache_param.save
			@id = @api_endpoint_request_cache_param.id

			if delete_old
				# Check if the old api_endpoint_request_param is still in the old database
				old_param = ApiEndpointRequestCacheParam.find_by(id: @id)
				old_param.destroy! if !old_param.nil?
			end

			return true
		end

		return false
	end

	def self.find_by(params)
		# Try to find the api_endpoint_request_cache_param in the new database
		api_endpoint_request_cache_param = ApiEndpointRequestCacheParamMigration.find_by(params)
		return ApiEndpointRequestCacheParamMigration.new(api_endpoint_request_cache_param.attributes) if !api_endpoint_request_cache_param.nil?

		# Try to find the api_endpoint_request_cache_param in the old database
		api_endpoint_request_cache_param = ApiEndpointRequestCacheParam.find_by(params)
		return api_endpoint_request_cache_param.nil? ? nil : ApiEndpointRequestCacheParamDelegate.new(api_endpoint_request_cache_param.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_endpoint_request_cache_params from the new database
		ApiEndpointRequestCacheParamMigration.where(params).each do |param|
			result.push(ApiEndpointRequestCacheParamDelegate.new(param.attributes))
		end

		# Get the api_endpoint_request_cache_params from the old database
		ApiEndpointRequestCacheParam.where(params).each do |param|
			# Check if the api_endpoint_request_cache_param is already in the results
			next if result.any? { |p| p.id == request_cache.id }	# TODO: Check for migrated
			result.push(ApiEndpointRequestCacheParamDelegate.new(param.attributes))
		end
	end
end