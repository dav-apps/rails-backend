class ApiErrorDelegate
	attr_reader :api_error
	attr_accessor :id, :api_id, :code, :message

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@api_id = attributes[:api_id]
		@code = attributes[:code]
		@message = attributes[:message]

		@api_error = ApiErrorMigration.find_by(id: @id)
		@api_error = ApiErrorMigration.new(id: @id) if @api_error.nil?
	end

	def attributes
		{
			id: @id,
			api_id: @api_id,
			code: @code,
			message: @message
		}
	end

	def save
		# Copy the values to the api_error
		@api_error.api_id = @api_id
		@api_error.code = @code
		@api_error.message = @message
		delete_old = false

		# Check the id
		if @api_error.id.nil?
			# Get the ids for the last api_error in the old and new database
			last_api_error = ApiError.last
			last_api_error_migration = ApiErrorMigration.last

			if !last_api_error.nil? && !last_api_error_migration.nil?
				if last_api_error.id >= last_api_error_migration.id
					@api_error.id = last_api_error.id + 1
				else
					@api_error.id = last_api_error_migration.id + 1
				end
			elsif !last_api_error.nil?
				@api_error.id = last_api_error.id + 1
			elsif !last_api_error_migration.nil?
				@api_error.id = last_api_error_migration.id + 1
			end
		else
			delete_old = true
		end

		if @api_error.save
			@id = @api_error.id

			if delete_old
				# Check if the api_error is still in the old database
				old_api_error = ApiError.find_by(id: @id)
				old_api_error.destroy! if !old_api_error.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the api_error in the old database
		api_error = ApiError.find_by(id: @id)
		api_error.destroy! if !api_error.nil?

		# Delete the api_error in the new database
		api_error = ApiErrorMigration.find_by(id: @id)
		api_error.destroy! if !api_error.nil?
	end

	def self.find_by(params)
		# Try to find the api_error in the new database
		api_error = ApiErrorMigration.find_by(params)
		return ApiErrorDelegate.new(api_error.attributes) if !api_error.nil?

		# Try to find the api_error in the old database
		api_error = ApiError.find_by(params)
		return api_error.nil? ? nil : ApiErrorDelegate.new(api_error.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the api_errors from the new database
		ApiErrorMigration.where(params).each do |api_error|
			result.push(ApiErrorDelegate.new(api_error.attributes))
		end

		# Get the api_errors from the new database
		ApiError.where(params).each do |api_error|
			# Check if the api_error is already in the results
			next if result.any? { |e| e.id == api_error.id }
			result.push(ApiErrorDelegate.new(api_error.attributes))
		end

		return result
	end
end