class TableObjectCollectionDelegate
	attr_reader :table_object_collection
	attr_accessor :id,
		:table_object_id,
		:collection_id,
		:created_at,
		:updated_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@table_object_id = attributes[:table_object_id]
		@collection_id = attributes[:collection_id]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@table_object_collection = TableObjectCollectionMigration.find_by(id: @id)
		@table_object_collection = TableObjectCollectionMigration.new(id: @id) if @table_object_collection.nil?
	end

	def attributes
		{
			id: @id,
			table_object_id: @table_object_id,
			collection_id: @collection_id,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the table_object_collection
		@table_object_collection.table_object_id = @table_object_id
		@table_object_collection.collection_id = @collection_id
		@table_object_collection.created_at = @created_at
		delete_old = false

		# Check the id
		if @table_object_collection.id.nil?
			# Get the ids for the last table_object_collection in the old and new database
			last_table_object_collection = TableObjectCollection.last
			last_table_object_collection_migration = TableObjectCollectionMigration.last

			if !last_table_object_collection.nil? && !last_table_object_collection_migration.nil?
				if last_table_object_collection.id >= last_table_object_collection_migration.id
					@table_object_collection.id = last_table_object_collection.id + 1
				else
					@table_object_collection.id = last_table_object_collection_migration.id + 1
				end
			elsif !last_table_object_collection.nil?
				@table_object_collection.id = last_table_object_collection.id + 1
			elsif !last_table_object_collection_migration.nil?
				@table_object_collection.id = last_table_object_collection_migration.id + 1
			end
		else
			delete_old = true
		end

		if @table_object_collection.save
			@id = @table_object_collection.id
			@created_at = @table_object_collection.created_at

			if delete_old
				# Check if the table_object_collection is still in the old database
				old_table_object_collection = TableObjectCollection.find_by(id: @id)
				old_table_object_collection.destroy! if !old_table_object_collection.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the table_object_collection in the old database
		table_object_collection = TableObjectCollection.find_by(id: @id)
		table_object_collection.destroy! if !table_object_collection.nil?

		# Delete the table_object_collection in the new database
		table_object_collection = TableObjectCollectionMigration.find_by(id: @id)
		table_object_collection.destroy! if !table_object_collection.nil?
	end

	def self.find_by(params)
		# Try to find the table_object_collection in the new database
		table_object_collection = TableObjectCollectionMigration.find_by(params)
		return TableObjectCollectionDelegate.new(table_object_collection.attributes) if !table_object_collection.nil?

		# Try to find the table_object_collection in the old database
		table_object_collection = TableObjectCollection.find_by(params)
		return table_object_collection.nil? ? nil : TableObjectCollectionDelegate.new(table_object_collection.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the table_object_collections from the new database
		TableObjectCollectionMigration.where(params).each do |table_object_collection|
			result.push(TableObjectCollectionDelegate.new(table_object_collection.attributes))
		end

		# Get the table_object_collections from the old database
		TableObjectCollection.where(params).each do |table_object_collection|
			# Check if the table_object_collection is already in the results
			next if result.any? { |obj_c| obj_c.id == table_object_collection.id }
			result.push(TableObjectCollectionDelegate.new(table_object_collection.attributes))
		end

		return result
	end
end