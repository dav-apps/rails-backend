namespace :push_notification_sender do
	task send_notifications: :environment do
		Notification.all.each do |notification|
			time = DateTime.parse(notification.time.to_s)
			current_time = DateTime.now

			# Check if the time of the notification is greater than the current time
			if current_time.to_i > time.to_i
				# Get the properties
				properties = Hash.new

				notification.notification_properties.each do |property|
					properties[property.name] = property.value
				end

				# Send the notification
				PushNotificationChannel.broadcast_to("#{notification.user.id},#{notification.app.id}", properties)

				if notification.interval == 0
					# Delete the notification
					notification.destroy!
				else
					# Update the notification
					notification.time = Time.at(time.to_i + notification.interval)
					notification.save
				end
			end
		end
	end
end