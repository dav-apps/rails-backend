class ApiEndpointRequestCacheDelegate
	attr_reader :api_endpoint_request_cache
	attr_accessor :id, :api_endpoint_id, :response, :created_at, :updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@api_endpoint_id = attributes[:api_endpoint_id]
		@response = attributes[:response]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@api_endpoint_request_cache = ApiEndpointRequestCacheMigration.find_by(id: @id)
		@api_endpoint_request_cache = ApiEndpointRequestCacheMigration.new(id: @id) if @api_endpoint_request_cache.nil?
	end

	def attributes
		{
			id: @id,
			api_endpoint_id: @api_endpoint_id,
			response: @response,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the api_endpoint_request_cache
		@api_endpoint_request_cache.api_endpoint_id = @api_endpoint_id
		@api_endpoint_request_cache.response = @response
		@api_endpoint_request_cache.created_at = @created_at
		@api_endpoint_request_cache.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @api_endpoint_request_cache.id.nil?
			# Get the ids for the api_endpoint_request_cache in the old and new database
			last_request_cache = ApiEndpointRequestCache.last
			last_request_cache_migration = ApiEndpointRequestCacheMigration.last

			if !last_request_cache.nil? && !last_request_cache_migration.nil?
				if last_request_cache.id >= last_request_cache_migration.id
					@api_endpoint_request_cache.id = last_request_cache.id + 1
				else
					@api_endpoint_request_cache.id = last_request_cache_migration.id + 1
				end
			elsif !last_request_cache.nil?
				@api_endpoint_request_cache.id = last_request_cache.id + 1
			elsif !last_request_cache_migration.nil?
				@api_endpoint_request_cache.id = last_request_cache_migration.id
			end
		else
			delete_old = true
		end

		if @api_endpoint_request_cache.save
			@id = @api_endpoint_request_cache.id
			@created_at = @api_endpoint_request_cache.created_at
			@updated_at = @api_endpoint_request_cache.updated_at

			if delete_old
				# Check if the api_endpoint_request_cache is still in the old database
				old_request_cache = ApiEndpointRequestCache.find_by(id: @id)
				old_request_cache.destroy! if !old_request_cache.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the api_endpoint_request_cache_params of the api_endpoint_request_cache
		ApiEndpointRequestCacheParamDelegate.where(api_endpoint_request_cache_id: @id).each { |param| param.destroy }

		# Delete the api_endpoint_request_cache in the old database
		api_endpoint_request_cache = ApiEndpointRequestCache.find_by(id: @id)
		api_endpoint_request_cache.destroy! if !api_endpoint_request_cache.nil?

		# Delete the api_endpoint_request_cache in the new database
		api_endpoint_request_cache = ApiEndpointRequestCacheMigration.find_by(id: @id)
		api_endpoint_request_cache.destroy! if !api_endpoint_request_cache.nil?
	end

	def self.find_by(params)
		# Try to find the api_endpoint_request_cache in the new database
		api_endpoint_request_cache = ApiEndpointRequestCacheMigration.find_by(params)
		return ApiEndpointRequestCacheDelegate.new(api_endpoint_request_cache.attributes) if !api_endpoint_request_cache.nil?

		# Try to find the api_endpoint_request_cache in the old database
		api_endpoint_request_cache = ApiEndpointRequestCache.find_by(params)
		return api_endpoint_request_cache.nil? ? nil : ApiEndpointRequestCacheDelegate.new(api_endpoint_request_cache.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_endpoint_request_caches from the new database
		ApiEndpointRequestCacheMigration.where(params).each do |request_cache|
			result.push(ApiEndpointRequestCacheDelegate.new(request_cache.attributes))
		end

		# Get the api_endpoint_request_caches from the old database
		ApiEndpointRequestCache.where(params).each do |request_cache|
			# Check if the api_endpoint_request_cache is already in the results
			next if result.any? { |c| c.id == request_cache.id }
			result.push(ApiEndpointRequestCacheDelegate.new(request_cache.attributes))
		end

		return result
	end
end