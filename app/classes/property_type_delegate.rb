class PropertyTypeDelegate
	attr_reader :property_type
	attr_accessor :id,
		:table_id,
		:name,
		:data_type

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@table_id = attributes[:table_id]
		@name = attributes[:name]
		@data_type = attributes[:data_type]

		@property_type = PropertyTypeMigration.find_by(id: @id)
		@property_type = PropertyTypeMigration.new(id: @id) if @property_type.nil?
	end

	def attributes
		{
			id: @id,
			table_id: @table_id,
			name: @name,
			data_type: @data_type
		}
	end

	def save
		# Copy the values to the property_type
		@property_type.table_id = @table_id
		@property_type.name = @name
		@property_type.data_type = @data_type
		delete_old = false

		# Check the id
		if @property_type.id.nil?
			# Get the ids for the last property_type in the old and new database
			last_property_type = PropertyType.last
			last_property_type_migration = PropertyTypeMigration.last

			if !last_property_type.nil? && !last_property_type_migration.nil?
				if last_property_type.id >= last_property_type_migration.id
					@property_type.id = last_property_type.id + 1
				else
					@property_type.id = last_property_type_migration.id + 1
				end
			elsif !last_property_type.nil?
				@property_type.id = last_property_type.id + 1
			elsif !last_property_type_migration.nil?
				@property_type.id = last_property_type_migration.id + 1
			end
		else
			delete_old = false
		end

		if @property_type.save
			@id = @property_type.id

			if delete_old
				# Check if the property_type is still in the old database
				old_property_type = PropertyType.find_by(id: @id)
				old_property_type.destroy! if !old_property_type.nil?
			end
			
			return true
		end

		return false
	end

	def self.find_by(params)
		# Try to find the property_type in the new database
		property_type = PropertyTypeMigration.find_by(params)
		return PropertyTypeDelegate.new(property_type.attributes) if !property_type.nil?

		# Try to find the property_type in the old database
		property_type = PropertyType.find_by(params)
		return property_type.nil? ? nil : PropertyTypeDelegate.new(property_type.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the property_types from the new database
		PropertyTypeMigration.where(params).each do |property_type|
			result.push(PropertyTypeDelegate.new(property_type.attributes))
		end

		PropertyType.where(params).each do |property_type|
			# Check if the property_type is already in the results
			next if result.any? { |t| t.id == property_type.id }
			result.push(PropertyTypeDelegate.new(property_type.attributes))
		end

		return result
	end
end