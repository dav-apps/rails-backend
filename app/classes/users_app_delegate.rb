class UsersAppDelegate
	attr_reader :users_app
	attr_accessor :id,
		:user_id,
		:app_id,
		:used_storage,
		:last_active,
		:created_at,
		:updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@app_id = attributes[:app_id]
		@used_storage = attributes[:used_storage]
		@last_active = attributes[:last_active]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@users_app = UsersAppMigration.find_by(id: @id)
		@users_app = UsersAppMigration.new(id: @id) if @users_app.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			app_id: @app_id,
			used_storage: @used_storage,
			last_active: @last_active,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the users_app
		@users_app.user_id = @user_id
		@users_app.app_id = @app_id
		@users_app.used_storage = @used_storage
		@users_app.last_active = @last_active
		@users_app.created_at = @created_at
		@users_app.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @users_app.id.nil?
			# Get the ids for the last users_app in the old and new database
			last_users_app = UsersApp.last
			last_users_app_migration = UsersAppMigration.last

			if !last_users_app.nil? && !last_users_app_migration.nil?
				if last_users_app.id >= last_users_app_migration.id
					@users_app.id = last_users_app.id + 1
				else
					@users_app.id = last_users_app_migration.id + 1
				end
			elsif !last_users_app.nil?
				@users_app.id = last_users_app.id + 1
			elsif !last_users_app_migration.nil?
				@users_app.id = last_users_app_migration.id + 1
			end
		else
			delete_old = true
		end

		if @users_app.save
			@id = @users_app.id

			if delete_old
				# Check if the users_app is still in the old database
				old_users_app = UsersApp.find_by(id: @id)
				old_users_app.destroy! if !old_users_app.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the users_app in the old database
		users_app = UsersApp.find_by(id: @id)
		users_app.destroy! if !users_app.nil?

		# Delete the users_app in the new database
		users_app = UsersAppMigration.find_by(id: @id)
		users_app.destroy! if !users_app.nil?
	end

	def self.find_by(params)
		# Try to find the users_app in the new database
		users_app = UsersAppMigration.find_by(params)
		return UsersAppDelegate.new(users_app.attributes) if !users_app.nil?

		# Try to find the users_app in the old database
		users_app = UsersApp.find_by(params)
		return users_app.nil? ? nil : UsersAppDelegate.new(users_app.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the users_apps from the new database
		UsersAppMigration.where(params).each do |users_app|
			result.push(UsersAppDelegate.new(users_app.attributes))
		end

		# Get the users_apps from the old database
		UsersApp.where(params).each do |users_app|
			# Check if the users_app is already in the results
			next if result.any? { |u| u.id == users_app.id }
			result.push(UsersAppDelegate.new(users_app.attributes))
		end

		return result
	end
end