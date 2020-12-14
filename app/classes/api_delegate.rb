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

	def self.find_by(params)
		# Try to find the api in the new database
		a = ApiMigration.find_by(params)
		return ApiMigration.new(a.attributes) if !a.nil?

		# Try to find the api in the old database
		a = Api.find_by(params)
		return a.nil? ? nil : ApiDelegate.new(a.attributes)
	end
end