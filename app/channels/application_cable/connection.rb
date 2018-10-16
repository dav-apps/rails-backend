# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
module ApplicationCable
	class Connection < ActionCable::Connection::Base
		identified_by :current_user, :current_app

      def connect
			# Authorize the user
			jwt = request.params["jwt"]
			app_id = request.params["app_id"]

			if !jwt || jwt.length < 2
				reject_unauthorized_connection
			end

			if !app_id
				reject_unauthorized_connection
			end
			
			# Validate the JWT
			begin
				decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
				self.current_user = decoded_jwt[0]
			rescue
				reject_unauthorized_connection
			end

			# Get the app
			self.current_app = App.find_by_id(app_id)

			if !self.current_app
				reject_unauthorized_connection
			end

			# Validate that the app belongs to the dev
			if self.current_app.dev_id != self.current_user["dev_id"]
				reject_unauthorized_connection
			end
      end
	end
end