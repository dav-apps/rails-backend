class PropertyDelegate
	attr_reader :property
	attr_accessor :id,
		:table_object_id,
		:name,
		:value

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@table_object_id = attributes[:table_object_id]
		@name = attributes[:name]
		@value = attributes[:value]
		
		@property = PropertyMigration.find_by(id: @id)
		@property = PropertyMigration.new(id: @id) if @property.nil?
	end

	def attributes
		{
			id: @id,
			table_object_id: @table_object_id,
			name: @name,
			value: @value
		}
	end

	def save
		# Copy the values to the property
		@property.table_object_id = @table_object_id
		@property.name = @name
		@property.value = @value
		delete_old = false

		# Check the id
		if @property.id.nil?
			# Get the ids for the last property in the old and new database
			last_property = Property.last
			last_property_migration = PropertyMigration.last

			if !last_property.nil? && !last_property_migration.nil?
				if last_property.id >= last_property_migration.id
					@property.id = last_property.id + 1
				else
					@property.id = last_property_migration.id + 1
				end
			elsif !last_property.nil?
				@property.id = last_property.id + 1
			elsif !last_property_migration.nil?
				@property.id = last_property_migration.id + 1
			end
		else
			delete_old = true
		end

		if @property.save
			@id = @property.id

			if delete_old
				# Check if the property is still in the old database
				old_property = Property.find_by(id: @id)
				old_property.destroy! if !old_property.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the property in the old database
		property = Property.find_by(id: @id)
		property.destroy! if !property.nil?

		# Delete the property in the new database
		property = PropertyMigration.find_by(id: @id)
		property.destroy! if !property.nil?
	end

	def self.find_by(params)
		# Try to find the property in the new database
		property = PropertyMigration.find_by(params)
		return PropertyDelegate.new(property.attributes) if !property.nil?

		# Try to find the property in the old database
		property = Property.find_by(params)
		return property.nil? ? nil : PropertyDelegate.new(property.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the property from the new database
		PropertyMigration.where(params).each do |property|
			result.push(PropertyDelegate.new(property.attributes))
		end

		# Get the properties from the old database
		Property.where(params).each do |property|
			# Check if the property is already in the results
			next if result.any? { |p| p.id == property.id }
			result.push(PropertyDelegate.new(property.attributes))
		end

		return result
	end
end