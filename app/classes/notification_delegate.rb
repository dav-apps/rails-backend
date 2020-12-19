class NotificationDelegate
	attr_reader :notification
	attr_accessor :id,
		:user_id,
		:app_id,
		:uuid,
		:time,
		:interval

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@app_id = attributes[:app_id]
		@uuid = attributes[:uuid]
		@time = attributes[:time]
		@interval = attributes[:interval]

		@notification = NotificationMigration.find_by(id: @id)
		@notification = NotificationMigration.new(id: @id) if @notification.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			app_id: @app_id,
			uuid: @uuid,
			time: @time,
			interval: @interval
		}
	end

	def save
		# Copy the values to the notification
		@notification.user_id = @user_id
		@notification.app_id = @app_id
		@notification.uuid = @uuid
		@notification.time = @time
		@notification.interval = @interval
		delete_old = false

		# Check the id
		if @notification.id.nil?
			# Get the ids for the last notification in the old and new database
			last_notification = Notification.last
			last_notification_migration = NotificationMigration.last

			if !last_notification.nil? && !last_notification_migration.nil?
				if last_notification.id >= last_notification_migration.id
					@notification.id = last_notification.id + 1
				else
					@notification.id = last_notification_migration.id + 1
				end
			elsif !last_notification.nil?
				@notification.id = last_notification.id + 1
			elsif !last_notification_migration.nil?
				@notification.id = last_notification_migration.id + 1
			end
		else
			delete_old = true
		end

		if @notification.save
			@id = @notification.id

			if delete_old
				# Check if the notification is still in the old database
				old_notification = Notification.find_by(id: @id)
				old_notification.destroy! if !old_notification.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the notification_properties of the notification
		NotificationPropertyDelegate.where(notification_id: @id).each { |property| property.destroy }

		# Delete the notification in the old database
		notification = Notification.find_by(id: @id)
		notification.destroy! if !notification.nil?

		# Delete the notification in the new database
		notification = NotificationMigration.find_by(id: @id)
		notification.destroy! if !notification.nil?
	end

	def self.find_by(params)
		# Try to find the notification in the new database
		notification = NotificationMigration.find_by(params)
		return NotificationDelegate.new(notification.attributes) if !notification.nil?

		# Try to find the notification in the old database
		notification = Notification.find_by(params)
		return notification.nil? ? nil : NotificationDelegate.new(notification.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the notifications from the new database
		NotificationMigration.where(params).each do |notification|
			result.push(NotificationDelegate.new(notification.attributes)) if !notification.nil?
		end

		# Get the notifications from the old database
		Notification.where(params).each do |notification|
			# Check if the notification is already in the results
			next if result.any? { |n| n.id == notification.id }
			result.push(NotificationDelegate.new(notification.attributes))
		end

		return result
	end
end