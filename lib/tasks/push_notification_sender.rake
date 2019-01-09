namespace :push_notification_sender do
	task send_notifications: :environment do
		Notification.where("time <= ?", DateTime.now).each do |notification|
			# Get the properties
			properties = Hash.new
			notification.notification_properties.each do |property|
				properties[property.name] = property.value
			end

			properties_json = JSON.generate(properties)

			# Send the notification
			PushNotificationChannel.broadcast_to("#{notification.user.id},#{notification.app.id}", properties)

			WebPushSubscription.where(user_id: notification.user_id).each do |subscription|
				send_web_push_notification(subscription, properties_json)
			end

			if notification.interval == 0
				# Delete the notification
				notification.destroy!
			else
				# Update the notification
				notification.time = Time.at(notification.time.to_i + notification.interval)
				notification.save
			end
		end
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
		rescue InvalidSubscription, ExpiredSubscription => e
			puts e
			
			# Delete the subscription
			subscription.destroy!
		end
	end
end