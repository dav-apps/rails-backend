class CollectionDelegate
	attr_reader :collection
	attr_reader :id,
		:table_id,
		:name,
		:created_at,
		:updated_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@table_id = attributes[:table_id]
		@name = attributes[:name]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@collection = CollectionMigration.find_by(id: @id)
		@collection = CollectionMigration.new(id: @id) if @collection.nil?
	end

	def attributes
		{
			id: @id,
			table_id: @table_id,
			name: @name,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the collection
		@collection.table_id = @table_id
		@collection.name = @name
		@collection.created_at = @created_at
		@collection.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @collection.id.nil?
			# Get the ids for the last collection in the old and new database
			last_collection = Collection.last
			last_collection_migration = CollectionMigration.last

			if !last_collection.nil? && !last_collection_migration.nil?
				if last_collection.id >= last_collection_migration.id
					@collection.id = last_collection.id + 1
				else
					@collection.id = last_collection_migration.id + 1
				end
			elsif !last_collection.nil?
				@collection.id = last_collection.id + 1
			elsif !last_collection_migration.nil?
				@collection.id = last_collection_migration.id + 1
			end
		else
			delete_old = true
		end

		if @collection.save
			@id = @collection.id
			@created_at = @collection.created_at
			@updated_at = @collection.updated_at

			if delete_old
				# Check if the collection is still in the old database
				old_collection = Collection.find_by(id: @id)
				old_collection.destroy! if !old_collection.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the table_object_collections of the collection
		TableObjectCollectionDelegate.where(collection_id: @id).each { |obj_c| obj_c.destroy }

		# Delete the collection in the old database
		collection = Collection.find_by(id: @id)
		collection.destroy! if !collection.nil?

		# Delete the collection in the new database
		collection = CollectionMigration.find_by(id: @id)
		collection.destroy! if !collection.nil?
	end

	def self.find_by(params)
		# Try to find the collection in the new database
		collection = CollectionMigration.find_by(params)
		return CollectionDelegate.new(collection.attributes) if !collection.nil?

		# Try to find the collection in the old database
		collection = Collection.find_by(params)
		return collection.nil? ? nil : CollectionDelegate.new(collection.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the collections from the new database
		CollectionMigration.where(params).each do |collection|
			result.push(CollectionDelegate.new(collection.attributes))
		end

		# Get the collections from the old database
		Collection.where(params).each do |collection|
			# Check if the collection is already in the results
			next if result.any? { |c| c.id == collection.id }
			result.push(CollectionDelegate.new(collection.attributes))
		end

		return result
	end
end