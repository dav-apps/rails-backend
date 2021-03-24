namespace :push_notification_sender do
	task send_notifications: :environment do
		Notification.where("time <= ?", DateTime.now.utc).each do |notification|
			# Update the notification first
			delete_notification = notification.interval == 0
			if !delete_notification
				# Update the notification
				notification.time = Time.at(notification.time.to_i + notification.interval)
				notification.save
			end

			# Generate the message
			properties = Hash.new
			notification.notification_properties.each do |property|
				properties[property.name] = property.value
			end

			message = Hash.new
			message["uuid"] = notification.uuid
			message["time"] = notification.time.to_i
			message["interval"] = notification.interval
			message["delete"] = notification.interval == 0
			message["properties"] = properties
			messageJson = JSON.generate(message)

			# Send the notification
			WebPushSubscription.where(user_id: notification.user_id).each do |subscription|
				send_web_push_notification(subscription, messageJson)
			end

			if delete_notification
				# Delete the notification
				notification.destroy!
			end
		end

		# Send the notifications on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/send_notifications", {}, {})
	end

	def send_web_push_notification(subscription, message)
		begin
			Webpush.payload_send(
				message: message,
				endpoint: subscription.endpoint,
				p256dh: subscription.p256dh,
				auth: subscription.auth,
				vapid: {
					subject: ENV["BASE_URL"],
					public_key: ENV["WEBPUSH_PUBLIC_KEY"],
					private_key: ENV["WEBPUSH_PRIVATE_KEY"]
				}
			)
		rescue Webpush::InvalidSubscription, Webpush::ExpiredSubscription => e
			puts e
			
			# Delete the subscription
			subscription.destroy!
		end
	end
end