class AppDelegate
	attr_reader :app
	attr_accessor :id,
		:dev_id,
		:name,
		:description,
		:published,
		:link_web,
		:link_play,
		:link_windows,
		:created_at,
		:updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)
		
		@id = attributes[:id]
		@dev_id = attributes[:dev_id]
		@name = attributes[:name]
		@description = attributes[:description]
		@published = attributes[:published]
		@link_web = attributes[:link_web]
		@link_play = attributes[:link_play]
		@link_windows = attributes[:link_windows]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@app = AppMigration.find_by(id: @id)
		@app = AppMigration.new(id: @id) if @app.nil?
	end

	def attributes
		{
			id: @id,
			dev_id: @dev_id,
			name: @name,
			description: @description,
			published: @published,
			link_web: @link_web,
			link_play: @link_play,
			link_windows: @link_windows,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the app
		@app.dev_id = @dev_id
		@app.name = @name
		@app.description = @description
		@app.published = @published
		@app.web_link = @link_web
		@app.google_play_link = @link_play
		@app.microsoft_store_link = @link_windows
		@app.created_at = @created_at
		@app.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @app.id.nil?
			# Get the ids for the last app in the old and new database
			last_app = App.last
			last_app_migration = AppMigration.last

			if !last_app.nil? && !last_app_migration.nil?
				if last_app.id >= last_app_migration.id
					@app.id = last_app.id + 1
				else
					@app.id = last_app_migration.id + 1
				end
			elsif !last_app.nil?
				@app.id = last_app.id + 1
			elsif !last_app.nil?
				@app.id = last_app_migration.id + 1
			end
		else
			delete_old = true
		end

		if @app.save
			@id = @app.id
			@created_at = @app.created_at
			@updated_at = @app.updated_at

			if delete_old
				# Check if the app is still in the old database
				old_app = App.find_by(id: @id)
				old_app.destroy! if !old_app.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the tables of the app
		TableDelegate.where(app_id: @id).each { |table| table.destroy }

		# Delete the apis of the app
		ApiDelegate.where(app_id: @id).each { |api| api.destroy }

		# Delete the active_app_users of the app
		ActiveAppUserDelegate.where(app_id: @id).each { |active_app_user| active_app_user.destroy }

		# Delete the exception_events of the app
		ExceptionEvent.where(app_id: @id).each { |exception_event| exception_event.destroy }

		# Delete the notifications of the app
		NotificationDelegate.where(app_id: @id).each { |notification| notification.destroy }

		# Delete the sessions of the app
		SessionDelegate.where(app_id: @id).each { |session| session.destroy }

		# Delete the users_apps of the app
		UsersAppDelegate.where(app_id: @id).each { |users_app| users_app.destroy }

		# Delete the app in the old database
		app = App.find_by(id: @id)
		app.destroy! if !app.nil?

		# Delete the app in the new database
		app = AppMigration.find_by(id: @id)
		app.destroy! if !app.nil?
	end

	def self.all
		result = Array.new

		# Get all apps from the new database
		AppMigration.all.each do |app|
			result.push(AppDelegate.new(app.attributes))
		end

		# Get all apps from the old database
		App.all.each do |app|
			# Check if the app is already in the results
			next if result.any? { |a| a.id == app.id }
			result.push(AppDelegate.new(app.attributes))
		end

		return result
	end

	def self.find_by(params)
		# Try to find the app in the new database
		a = AppMigration.find_by(params)
		return AppDelegate.new(a.attributes) if !a.nil?

		# Try to find the app in the old database
		a = App.find_by(params)
		return a.nil? ? nil : AppDelegate.new(a.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the apps from the new database
		AppMigration.where(params).each do |app|
			result.push(AppDelegate.new(app.attributes))
		end

		# Get the apps from the old database
		App.where(params).each do |app|
			# Check if the app is already in the results
			next if result.any? { |a| a.id == app.id }
			result.push(AppDelegate.new(app.attributes))
		end

		return result
	end
end