class PushNotificationChannel < ApplicationCable::Channel
	def subscribed
      stream_from "push_notification:#{current_user.id},#{current_app.id}"
   end
end