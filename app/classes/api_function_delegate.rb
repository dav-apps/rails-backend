class ApiFunctionDelegate
	attr_reader :api_function
	attr_accessor :id, :api_id, :name, :params, :commands

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@api_id = attributes[:api_id]
		@name = attributes[:name]
		@params = attributes[:params]
		@commands = attributes[:commands]

		@api_function = ApiFunctionMigration.find_by(id: @id)
		@api_function = ApiFunctionMigration.new(id: @id) if @api_function.nil?
	end

	def attributes
		{
			id: @id,
			api_id: @api_id,
			name: @name,
			params: @params,
			commands: @commands
		}
	end

	def save
		# Copy the values to the api_function
		@api_function.api_id = @api_id
		@api_function.name = @name
		@api_function.params = @params
		@api_function.commands = @commands
		delete_old = false

		# Check the id
		if @api_function.id.nil?
			# Get the ids for the last api_function in the old and new database
			last_api_function = ApiFunction.last
			last_api_function_migration = ApiFunctionMigration.last

			if !last_api_function.nil? && !last_api_function_migration.nil?
				if last_api_function.id >= last_api_function_migration.id
					@api_function.id = last_api_function.id + 1
				else
					@api_function.id = last_api_function_migration.id + 1
				end
			elsif !last_api_function.nil?
				@api_function.id = last_api_function.id + 1
			elsif !last_api_function_migration.nil?
				@api_function.id = last_api_function_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api_function.save
			@id = @api_function.id

			if delete_old
				# Check if the api_function is still in the old database
				old_api_function = ApiFunction.find_by(id: @id)
				old_api_function.destroy! if !old_api_function.nil?
			end

			return true
		end
		
		return false
	end

	def destroy
		# Delete the api_function in the old database
		api_function = ApiFunction.find_by(id: @id)
		api_function.destroy! if !api_function.nil?

		# Delete the api_function in the new database
		api_function = ApiFunctionMigration.find_by(id: @id)
		api_function.destroy! if !api_function.nil?
	end

	def self.find_by(params)
		# Try to find the api_function in the new database
		api_function = ApiFunctionMigration.find_by(params)
		return ApiFunctionDelegate.new(api_function.attributes) if !api_function.nil?

		# Try to find the api_function in the old database
		api_function = ApiFunction.find_by(params)
		return api_function.nil? ? nil : ApiFunctionDelegate.new(api_function.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_functions from the new database
		ApiFunctionMigration.where(params).each do |api_function|
			result.push(ApiFunctionDelegate.new(api_function.attributes))
		end

		# Get the api_functions from the old database
		ApiFunction.where(params).each do |api_function|
			# Check if the api_function is already in the results
			next if result.any? { |f| f.id == api_function.id }
			result.push(ApiFunctionDelegate.new(api_function.attributes))
		end

		return result
	end
end