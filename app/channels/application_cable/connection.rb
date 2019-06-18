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

			# Get the session id, if there is one
			jwt_parts = jwt.split(' ').last.split('.')
			jwt = jwt_parts[0..2].join('.')
			session_id = jwt_parts[3].to_i
			secret = ENV['JWT_SECRET']

			if session_id != 0
				session = Session.find_by_id(session_id)

				if !session
					# Session does not exist
					reject_unauthorized_connection
				end

				secret = session.secret
			end
			
			# Validate the JWT
			begin
				decoded_jwt = JWT.decode jwt, secret, true, { :algorithm => ENV['JWT_ALGORITHM'] }
				user = User.find_by_id(decoded_jwt[0]["user_id"])

				if(!user)
					reject_unauthorized_connection
				end

				self.current_user = user
			rescue
				reject_unauthorized_connection
			end

			# Get the app
			self.current_app = App.find_by_id(app_id)

			if !self.current_app
				reject_unauthorized_connection
			end
      end
	end
end