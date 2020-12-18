class TableObjectDelegate
	attr_reader :table_object
	attr_accessor :id,
		:user_id,
		:table_id,
		:uuid,
		:file,
		:created_at,
		:updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@table_id = attributes[:table_id]
		@uuid = attributes[:uuid]
		@file = attributes[:file]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@table_object = TableObjectMigration.find_by(id: @id)
		@table_object = TableObjectMigration.new(id: @id) if @table_object.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			table_id: @table_id,
			uuid: @uuid,
			file: @file,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the table_object
		@table_object.user_id = @user_id
		@table_object.table_id = @table_id
		@table_object.uuid = @uuid
		@table_object.file = @file
		@table_object.created_at = @created_at
		@table_object.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @table_object.id.nil?
			# Get the ids for the last table_object in the old and new database
			last_table_object = TableObject.last
			last_table_object_migration = TableObjectMigration.last

			if !last_table_object.nil? && !last_table_object_migration.nil?
				if last_table_object.id >= last_table_object_migration.id
					@table_object.id = last_table_object.id + 1
				else
					@table_object.id = last_table_object_migration.id + 1
				end
			elsif !last_table_object.nil?
				@table_object.id = last_table_object.id + 1
			elsif !last_table_object_migration.nil?
				@table_object.id = last_table_object_migration.id + 1
			end
		else
			delete_old = true
		end

		if @table_object.save
			@id = @table_object.id
			@created_at = @table_object.created_at
			@updated_at = @table_object.updated_at

			if delete_old
				# Check if the table object is still in the old database
				old_table_object = TableObject.find_by(id: @id)
				old_table_object.destroy! if !old_table_object.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the table_object in the old database
		table_object = TableObject.find_by(id: @id)
		table_object.destroy! if !table_object.nil?

		# Delete the app in the new database
		table_object = TableObjectMigration.find_by(id: @id)
		table_object.destroy! if !table_object.nil?
	end

	def self.find_by(params)
		# Try to find the table_object in the new database
		table_object = TableObjectMigration.find_by(params)
		return TableObjectDelegate.new(table_object.attributes) if !table_object.nil?

		# Try to find the table_object in the old database
		table_object = TableObject.find_by(params)
		return table_object.nil? ? nil : TableObjectDelegate.new(table_object.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the table_objects from the new database
		TableObjectMigration.where(params).each do |table_object|
			result.push(TableObjectDelegate.new(table_object.attributes))
		end

		# Get the table_objects from the old database
		TableObject.where(params).each do |table_object|
			# Check if the table_object is already in the results
			next if result.any? { |t| t.id == table_object.id }
			result.push(TableObjectDelegate.new(table_object.attributes))
		end

		return result
	end
end