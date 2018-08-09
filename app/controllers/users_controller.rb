class UsersController < ApplicationController
	
	def signup
		email = params[:email]
      password = params[:password]
		username = params[:username]
		auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			auth_validation = ValidationService.validate_auth_missing(auth)
			username_validation = ValidationService.validate_username_missing(username)
			email_validation = ValidationService.validate_email_missing(email)
			password_validation = ValidationService.validate_password_missing(password)
			errors = Array.new

			errors.push(auth_validation) if !auth_validation[:success]
			errors.push(username_validation) if !username_validation[:success]
			errors.push(email_validation) if !email_validation[:success]
			errors.push(password_validation) if !password_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]
			
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_email_taken(email))

			# Validate the properties
			email_validation = ValidationService.validate_email_not_valid(email)
			username_too_short_validation = ValidationService.validate_username_too_short(username)
			username_too_long_validation = ValidationService.validate_username_too_long(username)
			password_too_short_validation = ValidationService.validate_password_too_short(password)
			password_too_long_validation = ValidationService.validate_password_too_long(password)
			username_taken_validation = ValidationService.validate_username_taken(username)
			errors = Array.new

			errors.push(email_validation) if !email_validation[:success]
			errors.push(username_too_short_validation) if !username_too_short_validation[:success]
			errors.push(username_too_long_validation) if !username_too_long_validation[:success]
			errors.push(password_too_short_validation) if !password_too_short_validation[:success]
			errors.push(password_too_long_validation) if !password_too_long_validation[:success]
			errors.push(username_taken_validation) if !username_taken_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			# Create the new user
			user = User.new(email: email, password: password, username: username)
			user.email_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_verification_email(@user).deliver_later
			render json: user, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def login
		email = params[:email]
      password = params[:password]
		auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			auth_validation = ValidationService.validate_auth_missing(auth)
			email_validation = ValidationService.validate_email_missing(email)
			password_validation = ValidationService.validate_password_missing(password)
			errors = Array.new

			errors.push(auth_validation) if !auth_validation[:success]
			errors.push(email_validation) if !email_validation[:success]
			errors.push(password_validation) if  !password_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			user = User.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.authenticate_user(user, password))
			ValidationService.raise_validation_error(ValidationService.validate_user_is_confirmed(user))

			# Return the data
			# Create JWT and result
			result = Hash.new
         expHours = Rails.env.production? ? 7000 : 10000000
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         result["jwt"] = token
         result["user_id"] = user.id
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def login_by_jwt
		api_key = params[:api_key]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			api_key_validation = ValidationService.validate_api_key_missing(api_key)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(api_key_validation) if !api_key_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]
			
			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			dev_api_key = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev_api_key))

			# Return the data
			# Create JWT and result
			result = Hash.new
         expHours = Rails.env.production? ? 7000 : 10000000
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev_api_key.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         result["jwt"] = token
         result["user_id"] = user.id
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_user
		requested_user_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_user_id_missing(requested_user_id)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(id_validation) if !id_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			requested_user = User.find_by_id(requested_user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(requested_user))

			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(user, requested_user))

			# Return the data
			result = requested_user.attributes.except("email_confirmation_token", 
																	"password_confirmation_token", 
																	"new_password", 
																	"password_digest",
																	"stripe_customer_id")

			avatar_info = BlobOperationsService.get_avatar_information(user.id)
			result["avatar"] = avatar_info[0]
			result["avatar_etag"] = avatar_info[1]
			result["total_storage"] = get_total_storage(user.plan)
			result["used_storage"] = user.used_storage

			users_apps = Array.new
			UsersApp.where(user_id: requested_user.id).each do |users_app|
				app_hash = users_app.app.attributes
				app_hash["used_storage"] = users_app.used_storage
				users_apps.push(app_hash)
			end
			result["apps"] = users_apps
			result["archives"] = user.archives
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_user_by_jwt
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			result = user.attributes.except("email_confirmation_token", 
														"password_confirmation_token", 
														"new_password", 
														"password_digest",
														"stripe_customer_id")

			avatar_info = BlobOperationsService.get_avatar_information(user.id)
			result["avatar"] = avatar_info[0]
			result["avatar_etag"] = avatar_info[1]
			result["total_storage"] = get_total_storage(user.plan)
			result["used_storage"] = user.used_storage

			users_apps = Array.new
			UsersApp.where(user_id: user.id).each do |users_app|
				app_hash = users_app.app.attributes
				app_hash["used_storage"] = users_app.used_storage
				users_apps.push(app_hash)
			end
			result["apps"] = users_apps
			result["archives"] = user.archives
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def update_user
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			email_changed = false
			password_changed = false
			object = ValidationService.parse_json(request.body.string)

			email = object["email"]
			if email
				ValidationService.raise_validation_error(ValidationService.validate_email_not_valid(email))

				# Set email_confirmation_token and send email
				user.new_email = email
				user.email_confirmation_token = generate_token
				email_changed = true
			end

			username = object["username"]
			if username
				too_short_validation = ValidationService.validate_username_too_short(username)
				too_long_validation = ValidationService.validate_username_too_long(username)
				taken_validation = ValidationService.validate_username_taken(username)
				errors = Array.new

				errors.push(too_short_validation) if !too_short_validation[:success]
				errors.push(too_long_validation) if !too_long_validation[:success]
				errors.push(taken_validation) if !taken_validation[:success]

				if errors.length > 0
					raise RuntimeError, errors.to_json
				end

				user.username = username
			end

			password = object["password"]
			if password
				too_short_validation = ValidationService.validate_password_too_short(password)
				too_long_validation = ValidationService.validate_password_too_long(password)
				errors = Array.new

				errors.push(too_short_validation) if !too_short_validation[:success]
				errors.push(too_long_validation) if !too_long_validation[:success]

				if errors.length > 0
					raise RuntimeError, errors.to_json
				end

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

			payment_token = object["payment_token"]
			if payment_token
				# Check if the user is saved on stripe
				if user.stripe_customer_id
					# Get the customer object
					begin
						customer = Stripe::Customer.retrieve(user.stripe_customer_id)
						customer.source = payment_token
						customer.save
					rescue Stripe::InvalidRequestError => e
						ValidationService.raise_validation_error(ValidationService.get_payment_token_not_valid_error)
					end
				end

				if !customer
					begin
						# Create a new customer object with the token information
						customer = Stripe::Customer.create(
							:email => user.email,
							:source  => payment_token
						)

						user.stripe_customer_id = customer.id
					rescue Stripe::InvalidRequestError => e
						ValidationService.raise_validation_error(ValidationService.get_payment_token_not_valid_error)
					end
				end
			end

			plan = object["plan"]
			if plan
				ValidationService.raise_validation_error(ValidationService.validate_plan_exists(plan))
				ValidationService.raise_validation_error(ValidationService.validate_user_is_stripe_customer(user))

				# Process the payment
				plus_plan_product = Stripe::Product.retrieve(ENV['STRIPE_DAV_PLUS_PRODUCT_ID'])
				plus_plan = Stripe::Plan.retrieve(ENV['STRIPE_DAV_PLUS_EUR_PLAN_ID'])

				# Update the current subscription or create a new one
				subscription = Stripe::Subscription.list(customer: user.stripe_customer_id).data.first

				if !subscription
					if plan == 1
						# Create new subscription
						subscription = Stripe::Subscription.create(
							:customer => user.stripe_customer_id,
							:items => [
								{
									:plan => plus_plan.id,
								},
							]
						)
						user.plan = 1
						user.subscription_status = 0
					end
				else
					if plan == 0
						# Delete the subscription
						subscription.delete(at_period_end: true)
						user.subscription_status = 1
					elsif plan == 1
						# If the user is on plan 2
						if subscription.items.data[0].plan.product != plus_plan_product
							# Change the subscription to the plus plan
							subscription.items.data[0].plan = plus_plan.id
							subscription.save
							user.plan = 1
							user.subscription_status = 0
						end
					end
				end
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			result = user.attributes.except("email_confirmation_token", 
														"password_confirmation_token", 
														"new_password", 
														"password_digest",
														"stripe_customer_id")

			avatar_info = BlobOperationsService.get_avatar_information(user.id)
			result["avatar"] = avatar_info[0]
			result["avatar_etag"] = avatar_info[1]
			result["total_storage"] = get_total_storage(user.plan)
			result["used_storage"] = user.used_storage
			result["apps"] = user.apps
			result["archives"] = user.archives
			
			if email_changed
				UserNotifier.send_change_email_email(user).deliver_later
			end
			
			if password_changed
				UserNotifier.send_change_password_email(user).deliver_later
			end

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def delete_user
		email_confirmation_token = params[:email_confirmation_token]
      password_confirmation_token = params[:password_confirmation_token]
		user_id = params[:id]
		
		begin
			id_validation = ValidationService.validate_user_id_missing(user_id)
			email_confirmation_token_validation = ValidationService.validate_email_confirmation_token_missing(email_confirmation_token)
			password_confirmation_token_validation = ValidationService.validate_password_confirmation_token_missing(password_confirmation_token)
			errors = Array.new

			errors.push(id_validation) if !id_validation[:success]
			errors.push(email_confirmation_token_validation) if !email_confirmation_token_validation[:success]
			errors.push(password_confirmation_token_validation) if !password_confirmation_token_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

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
			user.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def remove_app
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		app_id = params["app_id"]
		
		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(app_id)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(id_validation) if !id_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Delete user app association
			ua = UsersApp.find_by(user_id: user_id, app_id: app_id)
			if ua
				ua.destroy!
			end

			RemoveAppWorker.perform_async(user.id, app.id)
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def confirm_user
		email_confirmation_token = params["email_confirmation_token"]
		user_id = params["id"]
		
		begin
			id_validation = ValidationService.validate_id_missing(user_id)
			token_validation = ValidationService.validate_email_confirmation_token_missing(email_confirmation_token)
			errors = Array.new

			errors.push(id_validation) if !id_validation[:success]
			errors.push(token_validation) if !token_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_user_is_not_confirmed(user))
			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))

			user.email_confirmation_token = nil
         user.confirmed = true
			user.save!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def send_verification_email
		email = params["email"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_email_missing(email))

			user = User.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_user_is_not_confirmed(user))
			
			user.email_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_verification_email(user).deliver_later
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def send_delete_account_email
		email = params["email"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_email_missing(email))

			user = User.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Generate password and email confirmation tokens
			user.password_confirmation_token = generate_token
			user.email_confirmation_token = generate_token

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_delete_account_email(user).deliver_later
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def send_reset_password_email
		email = params["email"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_email_missing(email))

			user = User.find_by(email: email)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			# Generate password confirmation token
			user.password_confirmation_token = generate_token
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_reset_password_email(user).deliver_later
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def set_password
		password_confirmation_token = params["password_confirmation_token"]
		password = params["password"]
		
		begin
			password_validation = ValidationService.validate_password_missing(password)
			token_validation = ValidationService.validate_password_confirmation_token_missing(password_confirmation_token)
			errors = Array.new

			errors.push(password_validation) if !password_validation[:success]
			errors.push(token_validation) if !token_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			user = User.find_by(password_confirmation_token: password_confirmation_token)
			ValidationService.raise_validation_error(ValidationService.get_password_confirmation_token_incorrect_error(!user))

			# Validate the password
			too_short_validation = ValidationService.validate_password_too_short(password)
			too_long_validation = ValidationService.validate_password_too_long(password)
			errors = Array.new

			errors.push(too_short_validation) if !too_short_validation[:success]
			errors.push(too_long_validation) if !too_long_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			user.password = password
			user.password_confirmation_token = nil

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def save_new_password
		user_id = params["id"]
		password_confirmation_token = params["password_confirmation_token"]
		
		begin
			id_validation = ValidationService.validate_id_missing(user_id)
			token_validation = ValidationService.validate_password_confirmation_token_missing(password_confirmation_token)
			errors = Array.new

			errors.push(id_validation) if !id_validation[:success]
			errors.push(token_validation) if !token_validation[:success]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_password_confirmation_token_of_user(user, password_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_new_password_empty(user.new_password))

			# Save new password
         user.password_digest = user.new_password
			user.new_password = nil
			user.password_confirmation_token = nil

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def save_new_email
		user_id = params["id"]
		email_confirmation_token = params["email_confirmation_token"]
		
		begin
			id_validation = ValidationService.validate_id_missing(user_id)
			token_validation = ValidationService.validate_email_confirmation_token_missing(email_confirmation_token)
			errors = Array.new

			errors.push(id_validation) if !id_validation[:success]
			errors.push(token_validation) if !token_validation[:success]
			
			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			ValidationService.raise_validation_error(ValidationService.validate_email_confirmation_token_of_user(user, email_confirmation_token))
			ValidationService.raise_validation_error(ValidationService.validate_new_email_empty(user.new_email))

			# Save new email
			user.old_email = user.email
			user.email = user.new_email
			user.new_email = nil
			user.email_confirmation_token = nil
			
			# Save the new email on stripe
			save_email_to_stripe_customer(user)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))

			UserNotifier.send_reset_new_email_email(user).deliver_later
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def reset_new_email
		user_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_id_missing(user_id))

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_old_email_empty(user.old_email))

			# Set new_email to email and email to old_email
			user.email = user.old_email
			user.old_email = nil
			
			# Save the new email on stripe
			save_email_to_stripe_customer(user)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def create_archive
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_max_archive_count(user))

			# Create the archive
			archive = Archive.new(user: user)
			archive.save

			archive.name = "dav-export-#{archive.id}.zip"
			archive.save

			ExportDataWorker.perform_async(user.id, archive.id)
			result = archive.attributes
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_archive
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		archive_id = params[:id]
		file = params[:file]

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_archive_id_missing(archive_id)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(id_Validation) if !id_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			archive = Archive.find_by_id(archive_id)
			ValidationService.raise_validation_error(ValidationService.validate_archive_does_not_exist(archive))

			ValidationService.raise_validation_error(ValidationService.validate_archive_belongs_to_user(archive, user))

			if file
				# Return the file itself
				result = BlobOperationsService.download_archive(archive.name)[1]
				send_data(result, status: 200, filename: archive.name)
			else
				# Return the archive object
				result = archive.attributes
				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def delete_archive
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		archive_id = params[:id]

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(archive_id)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(id_validation) if !id_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			
			archive = Archive.find_by_id(archive_id)
			ValidationService.raise_validation_error(ValidationService.validate_archive_does_not_exist(archive))

			ValidationService.raise_validation_error(ValidationService.validate_archive_belongs_to_user(archive, user))

			# Delete the archive
			archive.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
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