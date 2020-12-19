class ApiDelegate
	attr_reader :api
	attr_accessor :id, :app_id, :name

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@app_id = attributes[:app_id]
		@name = attributes[:name]

		@api = ApiMigration.find_by(id: @id)
		@api = ApiMigration.new(id: @id) if @api.nil?
	end

	def attributes
		{
			id: @id,
			app_id: @app_id,
			name: @name
		}
	end

	def save
		# Copy the values to the api
		@api.app_id = @app_id
		@api.name = @name
		delete_old = false

		# Check the id
		if @api.id.nil?
			# Get the ids for the last api in the old and new database
			last_api = Api.last
			last_api_migration = ApiMigration.last

			if !last_api.nil? && !last_api_migration.nil?
				if last_api.id >= last_api_migration.id
					@api.id = last_api.id + 1
				else
					@api.id = last_api_migration.id + 1
				end
			elsif !last_api.nil?
				@api.id = last_api.id + 1
			elsif !last_api_migration.nil?
				@api.id = last_api_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api.save
			@id = @api.id

			if delete_old
				# Check if the api is still in the old database
				old_api = Api.find_by(id: @id)
				old_api.destroy! if !old_api.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the api_endpoints of the api
		ApiEndpointDelegate.where(api_id: @id).each { |api_endpoint| api_endpoint.destroy }

		# Delete the api_env_vars of the api
		ApiEnvVarDelegate.where(api_id: @id).each { |api_env_var| api_env_var.destroy }

		# Delete the api_errors of the api
		ApiErrorDelegate.where(api_id: @id).each { |api_error| api_error.destroy }

		# Delete the api_functions of the api
		ApiFunctionDelegate.where(api_id: @id).each { |api_function| api_function.destroy }

		# Delete the api in the old database
		api = Api.find_by(id: @id)
		api.destroy! if !api.nil?

		# Delete the api in the new database
		api = ApiMigration.find_by(id: @id)
		api.destroy! if !api.nil?
	end

	def self.find_by(params)
		# Try to find the api in the new database
		a = ApiMigration.find_by(params)
		return ApiDelegate.new(a.attributes) if !a.nil?

		# Try to find the api in the old database
		a = Api.find_by(params)
		return a.nil? ? nil : ApiDelegate.new(a.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the apis from the new database
		ApiMigration.where(params).each do |api|
			result.push(ApiDelegate.new(api.attributes))
		end

		Api.where(params).each do |api|
			# Check if the api is already in the results
			next if result.any? { |a| a.id == api.id }
			result.push(ApiDelegate.new(api.attributes))
		end

		return result
	end
end