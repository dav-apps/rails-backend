class UsersController < ApplicationController
	jwt_expiration_hours_prod = 7000
	jwt_expiration_hours_dev = 10000000

	define_method :signup do
		auth = get_authorization_header
		email = params[:email]
      password = params[:password]
		username = params[:username]
		app_id = params[:app_id].to_i

		begin
			if app_id != 0
				# Get the device info from the body
				body = ValidationService.parse_json(request.body.string)
				dev_api_key = body['api_key']
				device_name = body['device_name']
				device_type = body['device_type']
				device_os = body['device_os']
			end

         validations = [
            ValidationService.validate_auth_missing(auth),
            ValidationService.validate_username_missing(username),
            ValidationService.validate_email_missing(email),
            ValidationService.validate_password_missing(password)
         ]

			# Validations for the session properties
         if app_id != 0
            validations.push(
					ValidationService.validate_api_key_missing(dev_api_key),
					ValidationService.validate_device_name_missing(device_name),
					ValidationService.validate_device_type_missing(device_type),
					ValidationService.validate_device_os_missing(device_os)
				)
         end

         ValidationService.raise_multiple_validation_errors(validations)

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]
			
			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_email_taken(email))

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_email_not_valid(email),
				ValidationService.validate_username_too_short(username),
				ValidationService.validate_username_too_long(username),
				ValidationService.validate_password_too_short(password),
				ValidationService.validate_password_too_long(password)
			])

			if app_id != 0
				# Check if the app belongs to the dev with the api key
				app_dev = DevDelegate.find_by(api_key: dev_api_key)
				ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(app_dev))

				app = AppDelegate.find_by(id: app_id)
				ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
				ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, app_dev))
			end

			# Create the new user
			user = UserDelegate.new(email: email, password: password, username: username)
			user.email_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			# Create a jwt
			expHours = Rails.env.production? ? jwt_expiration_hours_prod : jwt_expiration_hours_dev
			exp = Time.now.to_i + expHours * 3600

			if app_id != 0
				# Create a session jwt
				secret = SecureRandom.urlsafe_base64(30)

				# Create the session
				session = SessionDelegate.new(user_id: user.id, app_id: app_id, secret: secret, exp: Time.at(exp).utc, device_name: device_name, device_type: device_type, device_os: device_os)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(session.save))

				payload = {:email => user.email, :user_id => user.id, :dev_id => app_dev.id, :exp => exp}
				jwt = (JWT.encode(payload, secret, ENV['JWT_ALGORITHM'])) + ".#{session.id}"
			else
				# Create a normal jwt
				payload = {:email => user.email, :user_id => user.id, :dev_id => dev.id, :exp => exp}
				jwt = JWT.encode(payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM'])
			end
			
			UserNotifier.send_verification_email(user.user).deliver_later

			result = {
				id: user.attributes[:id],
				email: user.attributes[:email],
				username: user.attributes[:username],
				confirmed: user.attributes[:confirmed],
				plan: user.attributes[:plan],
				used_storage: user.attributes[:used_storage],
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				jwt: jwt
			}
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	define_method :login do
		auth = get_authorization_header
		email = params[:email]
      password = params[:password]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_auth_missing(auth),
				ValidationService.validate_email_missing(email),
				ValidationService.validate_password_missing(password)
			])

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			user = UserDelegate.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.authenticate_user(user, password))

			# Return the data
			# Create JWT and result
			result = Hash.new
         expHours = Rails.env.production? ? jwt_expiration_hours_prod : jwt_expiration_hours_dev
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         result["jwt"] = token
         result["user_id"] = user.id
			render json: result, status: 200
		rescue RuntimeError => e
         validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	define_method :login_by_jwt do
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		api_key = params[:api_key]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_api_key_missing(api_key)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]
			
			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			dev_api_key = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev_api_key))

			# Return the data
			# Create JWT and result
			result = Hash.new
         expHours = Rails.env.production? ? jwt_expiration_hours_prod : jwt_expiration_hours_dev
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev_api_key.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         result["jwt"] = token
         result["user_id"] = user.id
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	define_method :create_session do
      auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		
		begin
			# Make sure the body is json
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			# Get necessary information from the body
			body = ValidationService.parse_json(request.body.string)
			email = body['email']
			password = body['password']
			app_id = body['app_id']
         app_api_key = body['api_key']
         device_name = body['device_name']
         device_type = body['device_type']
         device_os = body['device_os']

			# Validate the params
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_auth_missing(auth),
				ValidationService.validate_email_missing(email),
				ValidationService.validate_password_missing(password),
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_api_key_missing(app_api_key),
				ValidationService.validate_device_name_missing(device_name),
				ValidationService.validate_device_type_missing(device_type),
				ValidationService.validate_device_os_missing(device_os)
			])

			# Get the info from the auth
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			website_api_key, signature = auth.split(",")

			# Get & validate the website dev
			website_dev = DevDelegate.find_by(api_key: website_api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(website_dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(website_dev))

			# Get & validate the app dev
			app_dev = DevDelegate.find_by(api_key: app_api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(app_dev))

			# Get & validate the app
			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, app_dev))

			# Get & validate the user
			user = UserDelegate.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))
			ValidationService.raise_validation_error(ValidationService.authenticate_user(user, password))

			# Generate secret
			secret = SecureRandom.urlsafe_base64(30)

			# Create session
			session = SessionDelegate.new(user_id: user.id, app_id: app.id, secret: secret, device_name: device_name, device_type: device_type, device_os: device_os)

			# Create JWT
			expHours = Rails.env.production? ? jwt_expiration_hours_prod : jwt_expiration_hours_dev
			exp = Time.now.to_i + expHours * 3600
			payload = {
				email: user.email,
				user_id: user.id,
				dev_id: app_dev.id,
				exp: exp
			}
			token = JWT.encode(payload, secret, ENV['JWT_ALGORITHM'])

			# Set the expiration time of the session
			session.exp = Time.at(exp).utc
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(session.save))

			# Append the session id at the end of the jwt
			token = token + ".#{session.id}"

			result = {
				id: session.id,
				user_id: session.user_id,
				app_id: session.app_id,
				device_name: session.device_name,
				device_type: session.device_type,
				device_os: session.device_os,
				exp: exp.to_i,
				jwt: token
			}
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	
	define_method :create_session_with_jwt do
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))
			
			body = ValidationService.parse_json(request.body.string)

			app_id = body['app_id']
         api_key = body['api_key']
         device_name = body['device_name']
         device_type = body['device_type']
         device_os = body['device_os']

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_api_key_missing(api_key),
				ValidationService.validate_device_name_missing(device_name),
				ValidationService.validate_device_type_missing(device_type),
				ValidationService.validate_device_os_missing(device_os)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			app_dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(app_dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, app_dev))

			# Generate secret
			secret = SecureRandom.urlsafe_base64(30)

			# Create the session
			session = SessionDelegate.new(user_id: user.id, app_id: app.id, secret: secret, device_name: device_name, device_type: device_type, device_os: device_os)

			# Create the JWT
			expHours = Rails.env.production? ? jwt_expiration_hours_prod : jwt_expiration_hours_dev
			exp = Time.now.to_i + expHours * 3600
			payload = {
				email: user.email,
				user_id: user.id,
				dev_id: app_dev.id,
				exp: exp
			}
			token = JWT.encode(payload, secret, ENV['JWT_ALGORITHM'])

			# Set the expiration time of the session
			session.exp = Time.at(exp).utc
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(session.save))

			# Append the session id at the end of the jwt
			token = "#{token}.#{session.id}"

			result = {
				id: session.id,
				user_id: session.user_id,
				app_id: session.app_id,
				device_name: session.device_name,
				device_type: session.device_type,
				device_os: session.device_os,
				exp: exp.to_i,
				jwt: token
			}
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
   
   def get_session
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		id = params[:id]
		
		begin
			# Validate the jwt
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			# Validate the user and dev from the jwt
			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get the session
			session = SessionDelegate.find_by(id: id)
			ValidationService.raise_validation_error(ValidationService.validate_session_does_not_exist(session))
			ValidationService.raise_validation_error(ValidationService.validate_session_belongs_to_user(session, user))

			# Return the session
			result = {
				id: session.id,
				user_id: session.user_id,
				app_id: session.app_id,
				device_name: session.device_name,
				device_type: session.device_type,
				device_os: session.device_os,
				exp: session.exp.to_i
			}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
   end

   def delete_session
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		
		begin
			# Validate the jwt
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			# Validate the user and dev from the jwt
			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			# Get the session
			session = SessionDelegate.find_by(id: session_id)
			ValidationService.raise_validation_error(ValidationService.validate_session_does_not_exist(session))
			ValidationService.raise_validation_error(ValidationService.validate_session_belongs_to_user(session, user))

			# Delete the session
			session.destroy

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
   end

	def get_user
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		requested_user_id = params["id"]
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			requested_user = UserDelegate.find_by(id: requested_user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(requested_user))

			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(user, requested_user))

			# Return the data
			avatar_info = BlobOperationsService.get_avatar_information(requested_user.id)

			result = {
				id: requested_user.id,
				email: requested_user.email,
				username: requested_user.username,
				confirmed: requested_user.confirmed,
				created_at: requested_user.created_at,
				updated_at: requested_user.updated_at,
				plan: requested_user.plan,
				avatar: avatar_info[0],
				avatar_etag: avatar_info[1],
				total_storage: UtilsService.get_total_storage(requested_user.plan, requested_user.confirmed),
				used_storage: requested_user.used_storage,
				dev: DevDelegate.find_by(user_id: requested_user.id) != nil,
				provider: ProviderDelegate.find_by(user_id: requested_user.id) != nil
			}

			users_apps = Array.new
			UsersAppDelegate.where(user_id: requested_user.id).each do |users_app|
				app_hash = AppDelegate.find_by(id: users_app.app_id).attributes
				app_hash["used_storage"] = users_app.used_storage
				users_apps.push(app_hash)
			end

			result["apps"] = users_apps

			if dev.id == DevDelegate.first.id
				result["old_email"] = requested_user.old_email
				result["new_email"] = requested_user.new_email
				result["period_end"] = requested_user.period_end
				result["subscription_status"] = requested_user.subscription_status
				result["stripe_customer_id"] = requested_user.stripe_customer_id
			end

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_user_by_auth
		auth = get_authorization_header
		user_id = params["id"]
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Return the data
			avatar_info = BlobOperationsService.get_avatar_information(user.id)

			result = {
				id: user.id,
				email: user.email,
				username: user.username,
				confirmed: user.confirmed,
				created_at: user.created_at,
				updated_at: user.updated_at,
				plan: user.plan,
				avatar: avatar_info[0],
				avatar_etag: avatar_info[1],
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				used_storage: user.used_storage,
				dev: DevDelegate.find_by(user_id: user.id) != nil,
				provider: ProviderDelegate.find_by(user_id: user.id) != nil
			}

			users_apps = Array.new
			UsersAppDelegate.where(user_id: user.id).each do |users_app|
				app_hash = App.find_by(id: users_app.app_id).attributes
				app_hash["used_storage"] = users_app.used_storage
				users_apps.push(app_hash)
			end

			result["apps"] = users_apps
			result["old_email"] = user.old_email
			result["new_email"] = user.new_email
			result["period_end"] = user.period_end
			result["subscription_status"] = user.subscription_status
			result["stripe_customer_id"] = user.stripe_customer_id

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_user_by_jwt
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			# Return the data
			avatar_info = BlobOperationsService.get_avatar_information(user.id)

			result = {
				id: user.id,
				email: user.email,
				username: user.username,
				confirmed: user.confirmed,
				created_at: user.created_at,
				updated_at: user.updated_at,
				plan: user.plan,
				avatar: avatar_info[0],
				avatar_etag: avatar_info[1],
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				used_storage: user.used_storage,
				dev: DevDelegate.find_by(user_id: user.id) != nil,
				provider: ProviderDelegate.find_by(user_id: user.id) != nil
			}

			users_apps = Array.new
			UsersAppDelegate.where(user_id: user.id).each do |users_app|
				app_hash = AppDelegate.find_by(id: users_app.app_id).attributes
				app_hash["used_storage"] = users_app.used_storage
				users_apps.push(app_hash)
			end

			result["apps"] = users_apps
			
			if dev.id == DevDelegate.first.id
				result["old_email"] = user.old_email
				result["new_email"] = user.new_email
				result["period_end"] = user.period_end
				result["subscription_status"] = user.subscription_status
				result["stripe_customer_id"] = user.stripe_customer_id
			end

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def update_user
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			email_changed = false
			password_changed = false
			object = ValidationService.parse_json(request.body.string)

			email = object["email"]
			if email
				ValidationService.raise_validation_error(ValidationService.validate_email_not_valid(email))
				ValidationService.raise_validation_error(ValidationService.validate_email_taken(email))

				# Set email_confirmation_token and send email
				user.new_email = email
				user.email_confirmation_token = generate_token
				email_changed = true
			end

			username = object["username"]
			if username
				ValidationService.raise_multiple_validation_errors([
					ValidationService.validate_username_too_short(username),
					ValidationService.validate_username_too_long(username)
				])

				user.username = username
			end

			password = object["password"]
			if password
				ValidationService.raise_multiple_validation_errors([
					ValidationService.validate_password_too_short(password),
					ValidationService.validate_password_too_long(password)
				])

				# Set password_confirmation_token and send email
				user.new_password = BCrypt::Password.create(password)
				user.password_confirmation_token = generate_token
				password_changed = true
			end

			avatar = object["avatar"]
			if avatar
				begin
					filename = user.id.to_s + ".png"
					bytes = Base64.decode64(avatar)
					img = MiniMagick::Image.read(bytes)
					format = img.type

					ValidationService.raise_validation_error(ValidationService.validate_file_extension_supported(format))

					png_bytes = img.to_blob { |attrs| attrs.format = 'PNG' }

					Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
					Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

					client = Azure::Blob::BlobService.new
					blob = client.create_block_blob(ENV["AZURE_AVATAR_CONTAINER_NAME"], filename, png_bytes)
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(false))
				end
			end
			
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			avatar_info = BlobOperationsService.get_avatar_information(user.id)

			result = {
				id: user.id,
				email: user.email,
				username: user.username,
				confirmed: user.confirmed,
				created_at: user.created_at,
				updated_at: user.updated_at,
				new_email: user.new_email,
				plan: user.plan,
				avatar: avatar_info[0],
				avatar_etag: avatar_info[1],
				total_storage: UtilsService.get_total_storage(user.plan, user.confirmed),
				used_storage: user.used_storage,
				dev: DevDelegate.find_by(user_id: user.id) != nil,
				provider: ProviderDelegate.find_by(user_id: user.id) != nil
			}
			
			apps = Array.new
			UsersAppDelegate.where(user_id: user.id).each do |users_app|
				app = AppDelegate.find_by(id: users_app.app_id)
				apps.push(app) if !app.nil?
			end

			result["apps"] = apps
			
			if email_changed
				UserNotifier.send_change_email_email(user.user).deliver_later
			end
			
			if password_changed
				UserNotifier.send_change_password_email(user.user).deliver_later
			end

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_stripe_customer_for_user
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Check if the user already has a stripe customer
			if user.stripe_customer_id
				# Try to get the stripe customer
				begin
					customer = Stripe::Customer.retrieve(user.stripe_customer_id)

					# Throw exception if the stripe customer exists
					ValidationService.raise_validation_error(ValidationService.validate_user_is_not_stripe_customer(user))
				rescue Stripe::InvalidRequestError => e
				end
			end

			# Create a new stripe customer
			customer = Stripe::Customer.create(
				email: user.email
			)

			user.stripe_customer_id = customer.id
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			render json: {stripe_customer_id: user.stripe_customer_id}, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_user
		auth = get_authorization_header
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)

			email_confirmation_token = body["email_confirmation_token"]
			password_confirmation_token = body["password_confirmation_token"]

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_email_confirmation_token_missing(email_confirmation_token),
				ValidationService.validate_password_confirmation_token_missing(password_confirmation_token)
			])

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			api_key = auth.split(",")[0]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Check if the tokens match the tokens of the user
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))

			# Delete the avatar of the user
			BlobOperationsService.delete_avatar(user.id)

			# Delete the stripe customer
			if user.stripe_customer_id
				customer = Stripe::Customer.retrieve(user.stripe_customer_id)
				if customer
					customer.delete
				end
			end

			# Delete the user
			DeleteUserWorker.perform_async(user.id)

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def remove_app
		auth = get_authorization_header
		app_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)

			user_id = body["user_id"]
			password_confirmation_token = body["password_confirmation_token"]

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_user_id_missing(user_id),
				ValidationService.validate_password_confirmation_token_missing(password_confirmation_token)
			])
			
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			api_key = auth.split(",")[0]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			app = App.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Check if the password confirmation token matches the password confirmation token of the user
			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))

			# Check if the user uses the app
			ua = UsersAppDelegate.find_by(user_id: user_id, app_id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user_of_app(ua))

			# Clear the password confirmation token
			user.password_confirmation_token = nil
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			# Delete user app association
			if ua
				ua.destroy
			end

			# Remove the app data
			RemoveAppWorker.perform_async(user.id, app.id)

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def confirm_user
		auth = get_authorization_header
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)

			email_confirmation_token = body["email_confirmation_token"]
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_missing(email_confirmation_token))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			api_key = auth.split(",")[0]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Check if the user is already confirmed
			ValidationService.raise_validation_error(ValidationService.validate_user_is_not_confirmed(user))

			# Check if the email confirmation token matches the email confirmation token of the user
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

			# Clear the email confirmation token and confirm the user
			user.email_confirmation_token = nil
			user.confirmed = true
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def send_verification_email
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])

			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Check if the user is already confirmed
			ValidationService.raise_validation_error(ValidationService.validate_user_is_not_confirmed(user))

			# Generate email confirmation token
			user.email_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_verification_email(user.user).deliver_later
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def send_delete_account_email
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])

			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Generate password and email confirmation tokens
			user.password_confirmation_token = generate_token
			user.email_confirmation_token = generate_token

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_delete_account_email(user.user).deliver_later
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def send_remove_app_email
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)

			app_id = body["app_id"]
			ValidationService.raise_validation_error(ValidationService.validate_app_id_missing(app_id))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Find the relationship between user and app
			ua = UsersAppDelegate.find_by(user_id: user.id, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user_of_app(ua))

			# Generate password_confirmation_token
			user.password_confirmation_token = generate_token

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			# Send email
			UserNotifier.send_remove_app_email(user.user, app.app).deliver_later
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def send_password_reset_email
		auth = get_authorization_header

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)
			
			email = body["email"]
			ValidationService.raise_validation_error(ValidationService.validate_email_missing(email))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Generate password confirmation token
			user.password_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			# Send the password reset email
			UserNotifier.send_password_reset_email(user.user).deliver_later
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_password
		auth = get_authorization_header

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)

			user_id = body["user_id"]
			password_confirmation_token = body["password_confirmation_token"]
			password = body["password"]

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_user_id_missing(user_id),
				ValidationService.validate_password_confirmation_token_missing(password_confirmation_token),
				ValidationService.validate_password_missing(password)
			])

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Check if the password confirmation token matches the password confirmation token of the user
			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))

			# Validate the new password
			ValidationService.raise_validation_error(ValidationService.validate_password_too_short(password))
			ValidationService.raise_validation_error(ValidationService.validate_password_too_long(password))

			# Save the new password
			user.password_digest = BCrypt::Password.create(password)
			user.password_confirmation_token = nil

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def save_new_password
		auth = get_authorization_header
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)
			password_confirmation_token = body["password_confirmation_token"]

			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_missing(password_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Check if the password confirmation token matches the password confirmation token of the user
			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_new_password_empty(user.new_password))

			# Save new password
         user.password_digest = user.new_password
			user.new_password = nil
			user.password_confirmation_token = nil

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def save_new_email
		auth = get_authorization_header
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			body = ValidationService.parse_json(request.body.string)
			email_confirmation_token = body["email_confirmation_token"]

			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_missing(email_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Check if the email confirmation token matches the email confirmation token of the user
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_new_email_empty(user.new_email))

			# Save the new email
			user.old_email = user.email
			user.email = user.new_email
			user.new_email = nil
			user.email_confirmation_token = nil

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			# Save the new email on stripe
			save_email_to_stripe_customer(user)

			# Send email to reset new email
			UserNotifier.send_reset_new_email_email(user.user).deliver_later

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def reset_new_email
		auth = get_authorization_header
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))
			ValidationService.raise_validation_error(ValidationService.validate_old_email_empty(user.old_email))

			# Set new_email to email and email to old_email
			user.email = user.old_email
			user.old_email = nil

			# Update the email on stripe
			save_email_to_stripe_customer(user)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

   private
   def generate_token
      SecureRandom.hex(20)
   end
   
   def validate_email(email)
      reg = Regexp.new("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      return (reg.match(email))? true : false
   end
end