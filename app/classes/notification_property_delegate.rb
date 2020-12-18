class NotificationPropertyDelegate
	attr_reader :notification_property
	attr_accessor :id,
		:notification_id,
		:name,
		:value
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@notification_id = attributes[:notification_id]
		@name = attributes[:name]
		@value = attributes[:value]

		@notification_property = NotificationPropertyMigration.find_by(id: @id)
		@notification_property = NotificationPropertyMigration.new(id: @id) if @notification_property.nil?
	end

	def attributes
		{
			id: @id,
			notification_id: @notification_id,
			name: @name,
			value: @value
		}
	end

	def save
		# Copy the values to the notification_property
		@notification_property.notification_id = @notification_id
		@notification_property.name = @name
		@notification_property.value = @value
		delete_old = false

		# Check the id
		if @notification_property.id.nil?
			# Get the ids for the last notification_property in the old and new database
			last_notification_property = NotificationProperty.last
			last_notification_property_migration = NotificationPropertyMigration.last

			if !last_notification_property.nil? && !last_notification_property_migration.nil?
				if last_notification_property.id >= last_notification_property_migration.id
					@notification_property.id = last_notification_property.id + 1
				else
					@notification_property.id = last_notification_property_migration.id + 1
				end
			elsif !last_notification_property.nil?
				@notification_property.id = last_notification_property.id + 1
			elsif !last_notification_property_migration.nil?
				@notification_property.id = last_notification_property_migration.id + 1
			end
		else
			delete_old = true
		end

		if @notification_property.save
			@id = @notification_property.id

			if delete_old
				# Check if the notification_property is still in the old database
				old_notification_property = NotificationProperty.find_by(id: @id)
				old_notification_property.destroy! if !old_notification_property.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the notification_property in the old database
		notification_property = NotificationProperty.find_by(id: @id)
		notification_property.destroy! if !notification_property.nil?

		# Delete the notification_property in the new database
		notification_property = NotificationPropertyMigration.find_by(id: @id)
		notification_property.destroy! if !notification_property.nil?
	end

	def self.find_by(params)
		# Try to find the notification_property in the new database
		notification_property = NotificationPropertyMigration.find_by(params)
		return NotificationPropertyDelegate.new(notification_property.attributes) if !notification_property.nil?

		# Try to find the notification_property in the old database
		notification_property = NotificationProperty.find_by(params)
		return notification_property.nil? ? nil : NotificationPropertyDelegate.new(notification_property.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the notification_properties from the new database
		NotificationPropertyMigration.where(params).each do |notification_property|
			result.push(NotificationPropertyDelegate.new(notification_property.attributes))
		end

		# Get the notification_properties from the old database
		NotificationProperty.where(params).each do |notification_property|
			# Check if the notification_property is already in the results
			next if result.any? { |prop| prop.id == notification_property.id }
			result.push(NotificationPropertyDelegate.new(notification_property.attributes))
		end

		return result
	end
end