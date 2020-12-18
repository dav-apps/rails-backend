class SessionDelegate
	attr_reader :session
	attr_accessor :id,
		:user_id,
		:app_id,
		:secret,
		:exp,
		:device_name,
		:device_type,
		:device_os,
		:created_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@app_id = attributes[:app_id]
		@secret = attributes[:secret]
		@exp = attributes[:exp]
		@device_name = attributes[:device_name]
		@device_type = attributes[:device_type]
		@device_os = attributes[:device_os]
		@created_at = attributes[:created_at]

		@session = SessionMigration.find_by(id: @id)
		@session = SessionMigration.new(id: @id) if @session.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			app_id: @app_id,
			secret: @secret,
			exp: @exp,
			device_name: @device_name,
			device_type: @device_type,
			device_os: @device_os,
			created_at: @created_at
		}
	end

	def save
		# Copy the values of the session
		@session.user_id = @user_id
		@session.app_id = @app_id
		@session.secret = @secret
		@session.exp = @exp
		@session.device_name = @device_name
		@session.device_type = @device_type
		@session.device_os = @device_os
		@session.created_at = @created_at
		delete_old = false

		# Check the id
		if @session.id.nil?
			# Get the ids for the last session in the old and new database
			last_session = Session.last
			last_session_migration = SessionMigration.last

			if !last_session.nil? && !last_session_migration.nil?
				if last_session.id >= last_session_migration.id
					@session.id = last_session.id + 1
				else
					@session.id = last_session_migration.id + 1
				end
			elsif !last_session.nil?
				@session.id = last_session.id + 1
			elsif !last_session_migration.nil?
				@session.id = last_session_migration.id + 1
			end
		else
			delete_old = true
		end

		if @session.save
			@id = @session.id
			@created_at = @session.created_at

			if delete_old
				# Check if the session is still in the old database
				old_session = Session.find_by(id: @id)
				old_session.destroy! if !old_session.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the session in the old database
		session = Session.find_by(id: @id)
		session.destroy! if !session.nil?

		# Delete the session in the new database
		session = SessionMigration.find_by(id: @id)
		session.destroy! if !session.nil?
	end

	def self.find_by(params)
		# Try to find the session in the new database
		session = SessionMigration.find_by(params)
		return SessionDelegate.new(session.attributes) if !session.nil?

		# Try to find the session in the old database
		session = Session.find_by(params)
		return session.nil? ? nil : SessionDelegate.new(session.attributes)
	end
end