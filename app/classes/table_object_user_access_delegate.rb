class TableObjectUserAccessDelegate
	attr_reader :table_object_user_access
	attr_accessor :id,
		:user_id,
		:table_object_id,
		:table_alias,
		:created_at,
		:updated_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@table_object_id = attributes[:table_object_id]
		@table_alias = attributes[:table_alias]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated]

		@table_object_user_access = TableObjectUserAccessMigration.find_by(id: @id)
		@table_object_user_access = TableObjectUserAccessMigration.new(id: @id) if @table_object_user_access.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			table_object_id: @table_object_id,
			table_alias: @table_alias,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the table_object_user_access
		@table_object_user_access.user_id = @user_id
		@table_object_user_access.table_object_id = @table_object_id
		@table_object_user_access.table_alias = @table_alias
		@table_object_user_access.created_at = @created_at
		delete_old = false

		# Check the id
		if @table_object_user_access.id.nil?
			# Get the ids for the last table_object_user_access in the old and new database
			last_user_access = TableObjectUserAccess.last
			last_user_access_migration = TableObjectUserAccessMigration.last

			if !last_user_access.nil? && !last_user_access_migration.nil?
				if last_user_access.id >= last_user_access_migration.id
					@table_object_user_access.id = last_user_access.id + 1
				else
					@table_object_user_access.id = last_user_access_migration.id + 1
				end
			elsif !last_user_access.nil?
				@table_object_user_access.id = last_user_access.id + 1
			elsif !last_user_access_migration.nil?
				@table_object_user_access.id = last_user_access_migration.id + 1
			end
		else
			delete_old = true
		end

		if @table_object_user_access.save
			@id = @table_object_user_access.id
			@created_at = @table_object_user_access.created_at

			if delete_old
				# Check if the table_object_user_access is still in the old database
				old_user_access = TableObjectUserAccess.find_by(id: @id)
				old_user_access.destroy! if !old_user_access.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the table_object_user_access in the old database
		user_access = TableObjectUserAccess.find_by(id: @id)
		user_access.destroy! if !user_access.nil?

		# Delete the table_object_user_access in the new database
		user_access = TableObjectUserAccessMigration.find_by(id: @id)
		user_access.destroy! if !user_access.nil?
	end

	def self.find_by(params)
		# Try to find the table_object_user_access in the new database
		user_access = TableObjectUserAccessMigration.find_by(params)
		return TableObjectUserAccessDelegate.new(user_access.attributes) if !user_access.nil?

		# Try to find the table_object_user_access in the old database
		user_access = TableObjectUserAccess.find_by(params)
		return user_access.nil? ? nil : TableObjectUserAccessDelegate.new(user_access.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the table_object_user_accesses from the new database
		TableObjectUserAccessMigration.where(params).each do |user_access|
			result.push(TableObjectUserAccessDelegate.new(user_access.attributes))
		end

		# Get the table_object_user_access from the old database
		TableObjectUserAccess.where(params).each do |user_access|
			# Check if the table_object_user_access is already in the results
			next if result.any? { |a| a.id == user_access.id }
			result.push(TableObjectUserAccessDelegate.new(user_access.attributes))
		end

		return result
	end
end