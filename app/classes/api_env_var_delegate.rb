class ApiEnvVarDelegate
	attr_reader :api_env_var
	attr_accessor :id, :api_id, :name, :value, :class_name

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)
		
		@id = attributes[:id]
		@api_id = attributes[:api_id]
		@name = attributes[:name]
		@value = attributes[:value]
		@class_name = attributes[:class_name]

		@api_env_var = ApiEnvVarMigration.find_by(id: @id)
		@api_env_var = ApiEnvVarMigration.new(id: @id) if @api_env_var.nil?
	end

	def attributes
		{
			id: @id,
			api_id: @api_id,
			name: @name,
			value: @value,
			class_name: @class_name
		}
	end

	def save
		# Copy the values to the api_env_var
		@api_env_var.api_id = @api_id
		@api_env_var.name = @name
		@api_env_var.value = @value
		@api_env_var.class_name = @class_name
		delete_old = false

		# Check the id
		if @api_env_var.id.nil?
			# Get the ids for the last api_env_var in the old and new database
			last_api_env_var = ApiEnvVar.last
			last_api_env_var_migration = ApiEnvVarMigration.last

			if !last_api_env_var.nil? && !last_api_env_var_migration.nil?
				if last_api_env_var.id >= last_api_env_var_migration.id
					@api_env_var.id = last_api_env_var.id + 1
				else
					@api_env_var.id = last_api_env_var_migration.id + 1
				end
			elsif !last_api_env_var.nil?
				@api_env_var.id = last_api_env_var.id + 1
			elsif !last_api_env_var_migration.nil?
				@api_env_var.id = last_api_env_var_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api_env_var.save
			@id = @api_env_var.id

			if delete_old
				# Check if the api_env_var is still in the old database
				old_api_env_var = ApiEnvVar.find_by(id: @id)
				old_api_env_var.destroy! if !old_api_env_var.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the api_env_var in the old database
		api_env_var = ApiEnvVar.find_by(id: @id)
		api_env_var.destroy! if !api_env_var.nil?

		# Delete the api_env_var in the new database
		api_env_var = ApiEnvVarMigration.find_by(id: @id)
		api_env_var.destroy! if !api_env_var.nil?
	end

	def self.find_by(params)
		# Try to find the api_env_var in the new database
		api_env_var = ApiEnvVarMigration.find_by(params)
		return ApiEnvVarDelegate.new(api_env_var.attributes) if !api_env_var.nil?

		# Try to find the api_env_var in the old database
		api_env_var = ApiEnvVar.find_by(params)
		return api_env_var.nil? ? nil : ApiEnvVarDelegate.new(api_env_var.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_env_vars from the new database
		ApiEnvVarMigration.where(params).each do |env_var|
			result.push(ApiEnvVarDelegate.new(env_var.attributes))
		end

		# Get the api_env_vars from the old database
		ApiEnvVar.where(params).each do |env_var|
			# Check if the api_env_var is already in the results
			next if result.any? { |e| e.id == env_var.id }	# TODO: Check for migrated
			result.push(ApiEnvVarDelegate.new(env_var.attributes))
		end

		return result
	end
end