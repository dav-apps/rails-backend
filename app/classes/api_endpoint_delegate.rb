class ApiEndpointDelegate
	attr_reader :api_endpoint
	attr_accessor :id, :api_id, :path, :method, :commands, :caching

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@api_id = attributes[:api_id]
		@path = attributes[:path]
		@method = attributes[:method]
		@commands = attributes[:commands]
		@caching = attributes[:caching]

		@api_endpoint = ApiEndpointMigration.find_by(id: @id)
		@api_endpoint = ApiEndpointMigration.new(id: @id) if @api_endpoint.nil?
	end

	def attributes
		{
			id: @id,
			api_id: @api_id,
			path: @path,
			method: @method,
			commands: @commands,
			caching: @caching
		}
	end

	def save
		# Copy the values to the api_endpoint
		@api_endpoint.api_id = @api_id
		@api_endpoint.path = @path
		@api_endpoint.method = @method
		@api_endpoint.commands = @commands
		@api_endpoint.caching = @caching
		delete_old = false

		# Check the id
		if @api_endpoint.id.nil?
			# Get the ids for the last api_endpoint in the old and new database
			last_api_endpoint = ApiEndpoint.last
			last_api_endpoint_migration = ApiEndpointMigration.last

			if !last_api_endpoint.nil? && !last_api_endpoint_migration.nil?
				if last_api_endpoint.id >= last_api_endpoint_migration.id
					@api_endpoint.id = last_api_endpoint.id + 1
				else
					@api_endpoint.id = last_api_endpoint_migration.id + 1
				end
			elsif !last_api_endpoint.nil?
				@api_endpoint.id = last_api_endpoint.id + 1
			elsif !last_api_endpoint_migration.nil?
				@api_endpoint.id = last_api_endpoint_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api_endpoint.save
			@id = @api_endpoint.id

			if delete_old
				# Check if the api_endpoint is still in the old database
				old_api_endpoint = ApiEndpoint.find_by(id: @id)
				old_api_endpoint.destroy! if !old_api_endpoint.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the api_endpoint_request_caches of the api_endpoint
		ApiEndpointRequestCacheDelegate.where(api_endpoint_id: @id).each { |api_endpoint_request_cache| api_endpoint_request_cache.destroy }

		# Delete the api_endpoint in the old database
		api_endpoint = ApiEndpoint.find_by(id: @id)
		api_endpoint.destroy! if !api_endpoint.nil?

		# Delete the api_endpoint in the new database
		api_endpoint = ApiEndpointMigration.find_by(id: @id)
		api_endpoint.destroy! if !api_endpoint.nil?
	end

	def self.find_by(params)
		# Try to find the api_endpoint in the new database
		api_endpoint = ApiEndpointMigration.find_by(params)
		return ApiEndpointDelegate.new(api_endpoint.attributes) if !api_endpoint.nil?

		# Try to find the api_endpoint in the old database
		api_endpoint = ApiEndpoint.find_by(params)
		return api_endpoint.nil? ? nil : ApiEndpointDelegate.new(api_endpoint.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_endpoints from the new database
		ApiEndpointMigration.where(params).each do |api_endpoint|
			result.push(ApiEndpointDelegate.new(api_endpoint.attributes))
		end

		# Get the api_endpoints from the old database
		ApiEndpoint.where(params).each do |api_endpoint|
			# Check if the api_endpoint is already in the results
			next if result.any? { |e| e.id == api_endpoint.id }
			result.push(ApiEndpointDelegate.new(api_endpoint.attributes))
		end

		return result
	end
end