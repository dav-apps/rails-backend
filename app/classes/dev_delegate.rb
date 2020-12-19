class DevDelegate
	attr_reader :dev
	attr_accessor :id, :user_id, :api_key, :secret_key, :uuid, :created_at, :updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@api_key = attributes[:api_key]
		@secret_key = attributes[:secret_key]
		@uuid = attributes[:uuid]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@dev = DevMigration.find_by(id: @id)
		@dev = DevMigration.new(id: @id) if @dev.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			api_key: @api_key,
			secret_key: @secret_key,
			uuid: @uuid,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the dev
		@dev.user_id = @user_id
		@dev.api_key = @api_key
		@dev.secret_key = @secret_key
		@dev.uuid = @uuid
		@dev.created_at = @created_at
		@dev.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @dev.id.nil?
			# Get the ids for the last dev in the old and new database
			last_dev = Dev.last
			last_dev_migration = DevMigration.last

			if !last_dev.nil? && !last_dev_migration.nil?
				if last_dev.id >= last_dev_migration.id
					@dev.id = last_dev.id + 1
				else
					@dev.id = last_dev_migration.id + 1
				end
			elsif !last_dev.nil?
				@dev.id = last_dev.id + 1
			elsif !last_dev_migration.nil?
				@dev.id = last_dev_migration.id + 1
			end
		else
			delete_old = true
		end

		if @dev.save
			@id = @dev.id
			@created_at = @dev.created_at
			@updated_at = @dev.updated_at

			if delete_old
				# Check if the dev is still in the old database
				old_dev = Dev.find_by(id: @id)
				old_dev.destroy! if !old_dev.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the apps of the dev
		AppDelegate.where(dev_id: @id).each { |app| app.destroy }

		# Delete the dev in the old database
		dev = Dev.find_by(id: @id)
		dev.destroy! if !dev.nil?

		# Delete the dev in the new database
		dev = DevMigration.find_by(id: @id)
		dev.destroy! if !dev.nil?
	end

	def self.first
		dev = DevMigration.first
		return dev if !dev.nil?

		dev = Dev.first
		return dev.nil? ? nil : dev
	end

	def self.find_by(params)
		# Try to find the dev in the new database
		d = DevMigration.find_by(params)
		return DevDelegate.new(d.attributes) if !d.nil?

		# Try to find the dev in the old database
		d = Dev.find_by(params)
		return d.nil? ? nil : DevDelegate.new(d.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the devs from the new database
		DevMigration.where(params).each do |dev|
			result.push(DevDelegate.new(dev.attributes))
		end

		# Get the devs from the old database
		Dev.where(params).each do |dev|
			# Check if the dev is already in the results
			next if result.any? { |d| d.id == dev.id }
			result.push(DevDelegate.new(dev.attributes))
		end

		return result
	end
end