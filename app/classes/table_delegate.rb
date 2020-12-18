class TableDelegate
	attr_reader :table
	attr_accessor :id,
		:app_id,
		:name,
		:created_at,
		:updated_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@app_id = attributes[:app_id]
		@name = attributes[:name]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@table = TableMigration.find_by(id: @id)
		@table = TableMigration.new(id: @id) if @table.nil?
	end

	def attributes
		{
			id: @id,
			app_id: @app_id,
			name: @name,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the table
		@table.app_id = @app_id
		@table.name = @name
		@table.created_at = @created_at
		@table.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @table.id.nil?
			# Get the ids for the last table in the old and new database
			last_table = Table.last
			last_table_migration = TableMigration.last

			if !last_table.nil? && !last_table_migration.nil?
				if last_table.id >= last_table_migration.id
					@table.id = last_table.id + 1
				else
					@table.id = last_table_migration.id + 1
				end
			elsif !last_table.nil?
				@table.id = last_table.id + 1
			elsif !last_table_migration.nil?
				@table.id = last_table_migration.id + 1
			end
		else
			delete_old = true
		end

		if @table.save
			@id = @table.id
			@created_at = @table.created_at
			@updated_at = @table.updated_at

			if delete_old
				# Check if the table is still in the old database
				old_table = Table.find_by(id: @id)
				old_table.destroy! if !old_table.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the table in the old database
		table = Table.find_by(id: @id)
		table.destroy! if !table.nil?

		# Delete the table in the new database
		table = TableMigration.find_by(id: @id)
		table.destroy! if !table.nil?
	end

	def self.find_by(params)
		# Try to find the table in the new database
		table = TableMigration.find_by(params)
		return TableDelegate.new(table.attributes) if !table.nil?

		# Try to find the table in the old database
		table = Table.find_by(params)
		return table.nil? ? nil : TableDelegate.new(table.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the tables from the new database
		TableMigration.where(params).each do |table|
			result.push(TableDelegate.new(table.attributes))
		end

		# Get the tables from the old database
		Table.where(params).each do |table|
			# Check if the table is already in the results
			next if result.any? { |t| t.id == table.id }
			result.push(TableDelegate.new(table.attributes))
		end

		return result
	end
end