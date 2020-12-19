class ExceptionEventDelegate
	attr_reader :exception_event
	attr_accessor :id,
		:app_id,
		:name,
		:message,
		:stack_trace,
		:app_version,
		:os_version,
		:device_family,
		:locale,
		:created_at
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@app_id = attributes[:app_id]
		@name = attributes[:name]
		@message = attributes[:message]
		@stack_trace = attributes[:stack_trace]
		@app_version = attributes[:app_version]
		@os_version = attributes[:os_version]
		@device_family = attributes[:device_family]
		@locale = attributes[:locale]
		@created_at = attributes[:created_at]

		@exception_event = ExceptionEventMigration.find_by(id: @id)
		@exception_event = ExceptionEventMigration.new(id: @id) if @exception_event.nil?
	end

	def attributes
		{
			id: @id,
			app_id: @app_id,
			name: @name,
			message: @message,
			stack_trace: @stack_trace,
			app_version: @app_version,
			os_version: @os_version,
			device_family: @device_family,
			locale: @locale,
			created_at: @created_at
		}
	end

	def save
		# Copy the values to the exception_event
		@exception_event.app_id = @app_id
		@exception_event.name = @name
		@exception_event.message = @message
		@exception_event.stack_trace = @stack_trace
		@exception_event.app_version = @app_version
		@exception_event.os_version = @os_version
		@exception_event.device_family = @device_family
		@exception_event.locale = @locale
		@exception_event.created_at = @created_at
		delete_old = false

		# Check the id
		if @exception_event.id.nil?
			# Get the ids for the last exception_event in the old and new database
			last_exception_event = ExceptionEvent.last
			last_exception_event_migration = ExceptionEventMigration.last

			if !last_exception_event.nil? && last_exception_event_migration.nil?
				if last_exception_event.id >= last_exception_event_migration.id
					@exception_event.id = last_exception_event.id + 1
				else
					@exception_event.id = last_exception_event_migration.id + 1
				end
			elsif !last_exception_event.nil?
				@exception_event.id = last_exception_event.id + 1
			elsif !last_exception_event_migration.nil?
				@exception_event.id = last_exception_event_migration.id + 1
			end
		else
			delete_old = true
		end

		if @exception_event.save
			@id = @exception_event.id
			@created_at = @exception_event.created_at

			if delete_old
				# Check if the old exception_event is still in the old database
				old_exception_event = ExceptionEvent.find_by(id: @id)
				old_exception_event.destroy! if !old_exception_event.nil?
			end

			return true
		end

		return false
	end

	def self.find_by(params)
		# Try to find the exception_event in the new database
		exception_event = ExceptionEventMigration.find_by(params)
		return ExceptionEventDelegate.new(exception_event.attributes) if !exception_event.nil?

		# Try to find the exception_event in the old database
		exception_event = ExceptionEvent.find_by(params)
		return exception_event.nil? ? nil : ExceptionEventDelegate.new(exception_event.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the exception_events from the new database
		ExceptionEventMigration.where(params).each do |exception_event|
			result.push(ExceptionEventDelegate.new(exception_event.attributes))
		end

		# Get the exception_events from the old database
		ExceptionEvent.where(params).each do |exception_event|
			# Check if the exception_event is already in the results
			next if result.any? { |e| e.id == exception_event.id }
			result.push(ExceptionEventDelegate.new(exception_event.attributes))
		end

		return result
	end
end