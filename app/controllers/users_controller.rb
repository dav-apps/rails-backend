class UsersController < ApplicationController
   require 'jwt'
   min_username_length = 2
   max_username_length = 25
   min_password_length = 7
	max_password_length = 25
	max_archive_count = 10
	
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

   def login_by_jwt_old
      api_key = params[:api_key]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

      errors = Array.new
      @result = Hash.new
      ok = false

      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 400
      end

      if !api_key || api_key.length < 1
         errors.push(Array.new([2118, "Missing field: api_key"]))
         status = 400
      end

      if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end

         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev_jwt = Dev.find_by_id(dev_id)
               
               if !dev_jwt
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  if dev_jwt != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     dev_api_key = Dev.find_by(api_key: api_key)

                     if !dev_api_key
                        errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                        status = 400
                     else
                        ok = true
                     end
                  end
               end
            end
         end
      end

      if ok && errors.length == 0
         # Create JWT and result
         expHours = Rails.env.production? ? 7000 : 10000000
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev_api_key.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         @result["jwt"] = token
         @result["user_id"] = user.id
         
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_user
      requested_user_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !requested_user_id
         errors.push(Array.new([2104, "Missing field: user_id"]))
         status = 400
      end
      
      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
      end
      
      if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end
         
         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  requested_user = User.find_by_id(requested_user_id)
                  
                  if !requested_user
                     errors.push(Array.new([2801, "Resource does not exist: User"]))
                     status = 404
                  else
                     # Check if the logged in user is the requested user
                     if requested_user.id != user.id
                        errors.push(Array.new([1102, "Action not allowed"]))
                        status = 403
							else
								@result = requested_user.attributes.except("email_confirmation_token", 
																						"password_confirmation_token", 
																						"new_password", 
																						"password_digest",
																						"stripe_customer_id")
								
								avatar_info = BlobOperationsService.get_avatar_information(user.id)
                        @result["avatar"] = avatar_info[0]
                        @result["avatar_etag"] = avatar_info[1]
                        @result["total_storage"] = get_total_storage(user.plan)
                        @result["used_storage"] = user.used_storage

								users_apps = Array.new
								UsersApp.where(user_id: requested_user.id).each do |users_app|
									app_hash = users_app.app.attributes
									app_hash["used_storage"] = users_app.used_storage
									users_apps.push(app_hash)
								end
								@result["apps"] = users_apps
								@result["archives"] = user.archives

                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end

   def get_user_by_jwt
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false

      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
      end

      if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end

         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]

            user = User.find_by_id(user_id)

            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
						@result = user.attributes.except("email_confirmation_token", 
																	"password_confirmation_token", 
																	"new_password", 
																	"password_digest",
																	"stripe_customer_id")
                  avatar_info = BlobOperationsService.get_avatar_information(user.id)
                  @result["avatar"] = avatar_info[0]
                  @result["avatar_etag"] = avatar_info[1]
                  @result["total_storage"] = get_total_storage(user.plan)
                  @result["used_storage"] = user.used_storage

						users_apps = Array.new
						UsersApp.where(user_id: user.id).each do |users_app|
							app_hash = users_app.app.attributes
							app_hash["used_storage"] = users_app.used_storage
							users_apps.push(app_hash)
						end
						@result["apps"] = users_apps
						@result["archives"] = user.archives

                  ok = true
               end
            end
         end
      end

      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :update_user do
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
		ok = false
      
      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
		end
      
		if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end
         
         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Check if the call was made from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     if request.headers["Content-Type"] != "application/json" && request.headers["Content-Type"] != "application/json; charset=utf-8"
                        errors.push(Array.new([1104, "Content-type not supported"]))
                        status = 415
                     else
                        email_changed = false
								password_changed = false
								
								begin
                        	json = request.body.string
									object = json && json.length >= 2 ? JSON.parse(json) : Hash.new
								rescue Exception => e
									errors.push(Array.new([1103, "Unknown validation error"]))
									status = 500
								end
								
								if errors.length == 0
									email = object["email"]
									if email && email.length > 0
										if !validate_email(email)
											errors.push(Array.new([2401, "Field not valid: email"]))
											status = 400
										end
										
										if errors.length == 0
											# Set email_confirmation_token and send email
											user.new_email = email
											user.email_confirmation_token = generate_token
											email_changed = true
										end
									end
									
									username = object["username"]
									if username && username.length > 0
										if username.length < min_username_length
											errors.push(Array.new([2201, "Field too short: username"]))
											status = 400
										end
										
										if username.length > max_username_length
											errors.push(Array.new([2301, "Field too long: username"]))
											status = 400
										end
										
										if User.exists?(username: username)
											errors.push(Array.new([2701, "Field already taken: username"]))
											status = 400
										end
										
										if errors.length == 0
											user.username = username
										end
									end
									
									password = object["password"]
									if password && password.length > 0
										if password.length < min_password_length
											errors.push(Array.new([2202, "Field too short: password"]))
											status = 400
										end
										
										if password.length > max_password_length
											errors.push(Array.new([2302, "Field too long: password"]))
											status = 400
										end
										
										if errors.length == 0
											# Set password_confirmation_token and send email
											user.new_password = BCrypt::Password.create(password)
											user.password_confirmation_token = generate_token
											password_changed = true
										end
									end

									avatar = object["avatar"]
									if avatar && avatar.length > 0
										if errors.length == 0
											begin
												filename = user.id.to_s + ".png"
												bytes = Base64.decode64(avatar)
												img = MiniMagick::Image.read(bytes)
												format = img.type

												if format == "png" || format == "PNG" || format == "jpg" || format == "JPG" || format == "jpeg" || format == "JPEG"
													# file extension okay
													png_bytes = img.to_blob { |attrs| attrs.format = 'PNG' }

													Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
													Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

													client = Azure::Blob::BlobService.new
													blob = client.create_block_blob(ENV["AZURE_AVATAR_CONTAINER_NAME"], filename, png_bytes)
												else
													errors.push(Array.new([1109, "File extension not supported"]))
													status = 400
												end
											rescue Exception => e
												puts e
												errors.push(Array.new([1103, "Unknown validation error"]))
												status = 400
											end
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
												errors.push(Array.new([2405, "Field not valid: payment_token"]))
												status = 400
											end
										end
										
										if !customer && errors.length == 0
											begin
												# Create a new customer object with the token information
												customer = Stripe::Customer.create(
													:email => user.email,
													:source  => payment_token
												)

												user.stripe_customer_id = customer.id
											rescue Stripe::InvalidRequestError => e
												errors.push(Array.new([2405, "Field not valid: payment_token"]))
												status = 400
											end
										end
									end

									plan = object["plan"]

									if plan
										if plan != 0 && plan != 1
											errors.push(Array.new([1108, "Plan does not exist"]))
											status = 400
										else
											# Check if the user is saved on stripe
											if !user.stripe_customer_id
												errors.push(Array.new([1113, "Please add your payment information"]))
												status = 400
											else
												# Get the customer object
												begin
													customer = Stripe::Customer.retrieve(user.stripe_customer_id)
												rescue => e
													puts e
												end

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
										end
									end

									
									if errors.length == 0
										# Update user with new properties
										if !user.save
											errors.push(Array.new([1103, "Unknown validation error"]))
											status = 500
										else
											@result = user.attributes.except("email_confirmation_token", 
																						"password_confirmation_token", 
																						"new_password", 
																						"password_digest",
																						"stripe_customer_id")
											avatar_info = BlobOperationsService.get_avatar_information(user.id)
											@result["avatar"] = avatar_info[0]
											@result["avatar_etag"] = avatar_info[1]
											@result["total_storage"] = get_total_storage(user.plan)
											@result["used_storage"] = user.used_storage
											@result["apps"] = user.apps
											@result["archives"] = user.archives

											ok = true
											
											if email_changed
												UserNotifier.send_change_email_email(user).deliver_later
											end
											
											if password_changed
												UserNotifier.send_change_password_email(user).deliver_later
											end
										end
									end
								end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def delete_user
      email_confirmation_token = params[:email_confirmation_token]
      password_confirmation_token = params[:password_confirmation_token]
      user_id = params[:id]

      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email_confirmation_token || email_confirmation_token.length < 1
         errors.push(Array.new([2108, "Missing field: email_confirmation_token"]))
         status = 400
      end

      if !password_confirmation_token || password_confirmation_token.length < 1
         errors.push(Array.new([2109, "Missing field: password_confirmation_token"]))
         status = 400
      end

      if !user_id
         errors.push(Array.new([2104, "Missing field: user_id"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if user.email_confirmation_token != email_confirmation_token
               errors.push(Array.new([1204, "Email confirmation token is not correct"]))
               status = 400
            else
               if user.password_confirmation_token != password_confirmation_token
                  errors.push(Array.new([1203, "Password confirmation token is not correct"]))
                  status = 400
               else
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
                  @result = {}
                  ok = true
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end

   def remove_app
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      app_id = params["app_id"]

      errors = Array.new
      @result = Hash.new
      ok = false

      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
      end

      if !app_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end

      if errors.length == 0
         if errors.length == 0
            jwt_valid = false
            begin
               decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
               jwt_valid = true
            rescue JWT::ExpiredSignature
               # JWT expired
               errors.push(Array.new([1301, "JWT: expired"]))
               status = 401
            rescue JWT::DecodeError
               errors.push(Array.new([1302, "JWT: not valid"]))
               status = 401
               # rescue other errors
            rescue Exception
               errors.push(Array.new([1303, "JWT: unknown error"]))
               status = 401
            end
            
            if jwt_valid
               user_id = decoded_jwt[0]["user_id"]
               dev_id = decoded_jwt[0]["dev_id"]
               
               user = User.find_by_id(user_id)
               
               if !user
                  errors.push(Array.new([2801, "Resource does not exist: User"]))
                  status = 400
               else
                  dev = Dev.find_by_id(dev_id)
                  
                  if !dev
                     errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                     status = 400
                  else
                     app = App.find_by_id(app_id)

                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        if dev != Dev.first
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           # Delete user app association
                           ua = UsersApp.find_by(user_id: user_id, app_id: app_id)
                           if ua
                              ua.destroy!
                           end

                           RemoveAppWorker.perform_async(user.id, app.id)

                           @result = {}
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end

      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def confirm_user
      email_confirmation_token = params["email_confirmation_token"]
      user_id = params["id"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email_confirmation_token || email_confirmation_token.length < 1
         errors.push(Array.new([2108, "Missing field: email_confirmation_token"]))
         status = 400
      end
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if user.confirmed == true
               errors.push(Array.new([1106, "User is already confirmed"]))
               status = 400
            else
               if user.email_confirmation_token != email_confirmation_token
                  errors.push(Array.new([1204, "Email confirmation token is not correct"]))
                  status = 400
               else
                  user.email_confirmation_token = nil
                  user.confirmed = true
                  user.save!
                  
                  ok = true
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def send_verification_email
      email = params["email"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by(email: email)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if user.confirmed == true
               errors.push(Array.new([1106, "User is already confirmed"]))
               status = 400
            else
               user.email_confirmation_token = generate_token
               if !user.save
                  errors.push(Array.new([1103, "Unknown validation error"]))
                  status = 500
               else
                  ok = true
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
			# Send email
			UserNotifier.send_verification_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end

   def send_delete_account_email
      email = params["email"]

      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end

      if errors.length == 0
         user = User.find_by(email: email)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            # Generate password and email confirmation tokens
            user.password_confirmation_token = generate_token
            user.email_confirmation_token = generate_token
            
            if !user.save
               errors.push(Array.new([1103, "Unknown validation error"]))
               status = 500
            else
               ok = true
            end
         end
      end

      if ok && errors.length == 0
         status = 200
			# Send email
			UserNotifier.send_delete_account_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def send_reset_password_email
      email = params["email"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by(email: email)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            # Generate password confirmation token
            user.password_confirmation_token = generate_token
            if !user.save
               errors.push(Array.new([1103, "Unknown validation error"]))
               status = 500
            else
               ok = true
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
			# Send email
			UserNotifier.send_reset_password_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :set_password do
      password_confirmation_token = params["password_confirmation_token"]
      password = params["password"]

      errors = Array.new
      @result = Hash.new
      ok = false

      if !password_confirmation_token || password_confirmation_token.length < 1
         errors.push(Array.new([2109, "Missing field: password_confirmation_token"]))
         status = 400
      end

      if !password || password.length < 1
         errors.push(Array.new([2107, "Missing field: password"]))
         status = 400
      end

      if errors.length == 0
         user = User.find_by(password_confirmation_token: password_confirmation_token)

         if !user
            errors.push(Array.new([1203, "Password confirmation token is not correct"]))
            status = 400
         else
            # Validate password
            if password.length < min_password_length
               errors.push(Array.new([2202, "Field too short: password"]))
               status = 400
            end
            
            if password.length > max_password_length
               errors.push(Array.new([2302, "Field too long: password"]))
               status = 400
            end
            
            if errors.length == 0
               user.password = password
               user.password_confirmation_token = nil

               if !user.save
                  errors.push(Array.new([1103, "Unknown validation error"]))
                  status = 500
               else
                  ok = true
               end
            end
         end
      end

      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end

   def save_new_password
      user_id = params["id"]
      password_confirmation_token = params["password_confirmation_token"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if !password_confirmation_token || password_confirmation_token.length < 1
         errors.push(Array.new([2109, "Missing field: password_confirmation_token"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if password_confirmation_token != user.password_confirmation_token
               errors.push(Array.new([1203, "Password confirmation token is not correct"]))
               status = 400
            else
               if user.new_password == nil || user.new_password.length < 1
                  errors.push(Array.new([2603, "Field is empty: new_password"]))
                  status = 400
               else
                  # Save new password
                  user.password_digest = user.new_password
                  user.new_password = nil
                  
                  user.password_confirmation_token = nil
                  
                  if !user.save
                     errors.push(Array.new([1103, "Unknown validation error"]))
                     status = 500
                  else
                     ok = true
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def save_new_email
      user_id = params["id"]
      email_confirmation_token = params["email_confirmation_token"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if !email_confirmation_token || email_confirmation_token.length < 1
         errors.push(Array.new([2108, "Missing field: email_confirmation_token"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if email_confirmation_token != user.email_confirmation_token
               errors.push(Array.new([1204, "Email confirmation token is not correct"]))
               status = 400
            else
               if user.new_email == nil || user.new_email.length < 1
                  errors.push(Array.new([2601, "Field is empty: new_email"]))
                  status = 400
               else
                  # Save new email
                  user.old_email = user.email
                  user.email = user.new_email
                  user.new_email = nil
                  
						user.email_confirmation_token = nil
						
						# Save the new email on stripe
						save_email_to_stripe_customer(user)
                  
                  if !user.save
                     errors.push(Array.new([1103, "Unknown validation error"]))
                     status = 500
                  else
                     ok = true
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
			status = 200
			UserNotifier.send_reset_new_email_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def reset_new_email
      # This method exists to reset the new email, when the email change was not intended by the account owner
      user_id = params["id"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if !user.old_email || user.old_email.length < 1
               errors.push(Array.new([2602, "Field is empty: old_email"]))
               status = 400
            else
               # set new_email to email and email to old_email
               user.email = user.old_email
					user.old_email = nil
					
					# Save the new email on stripe
					save_email_to_stripe_customer(user)
               
               if !user.save
                  errors.push(Array.new([1103, "Unknown validation error"]))
                  status = 500
               else
                  ok = true
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
	end
	
	define_method :create_archive do
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		errors = Array.new
      @result = Hash.new
		ok = false
		
		if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
		end
		
		if errors.length == 0
			jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
			end
			
			if jwt_valid
				user_id = decoded_jwt[0]["user_id"]
				dev_id = decoded_jwt[0]["dev_id"]
				
				user = User.find_by_id(user_id)

				if !user
					errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
				else
					dev = Dev.find_by_id(dev_id)

					if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						# Check if the call was made from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
						else
							# Check if the user can create more archives
							if user.archives.count >= max_archive_count
								errors.push(Array.new([1112, "You can't create more than #{max_archive_count} archives"]))
                     	status = 422
							else
								archive = Archive.new(user: user)
								archive.save

								archive.name = "dav-export-#{archive.id}.zip"
								archive.save
	
								ExportDataWorker.perform_async(user.id, archive.id)

								@result = archive.attributes
								ok = true
							end
						end
					end
				end
			end
		end

		if ok && errors.length == 0
         status = 201
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
	end
	
	def get_archive
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		archive_id = params[:id]
		file = params[:file]

		errors = Array.new
      @result = Hash.new
		ok = false

		if !archive_id
         errors.push(Array.new([2119, "Missing field: archive_id"]))
         status = 400
      end
		
		if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
		end

		if errors.length == 0
			jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
			end
			
			if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
				dev_id = decoded_jwt[0]["dev_id"]
				
				user = User.find_by_id(user_id)

				if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
				else
					dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
						else
							archive = Archive.find_by_id(archive_id)

							if !archive
								errors.push(Array.new([2810, "Resource does not exist: Archive"]))
								status = 404
							else
								# Check if the archive belongs to the user
								if archive.user != user
									errors.push(Array.new([1102, "Action not allowed"]))
                        	status = 403
								else
									if file
										# Return the file itself
										@result = BlobOperationsService.download_archive(archive.id)[1]
									else
										# Return the archive object
										@result = archive.attributes
									end

									ok = true
								end
							end
						end
					end
				end
			end
		end

		if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
		
		if file
			send_data(@result, status: status, filename: archive.name)
		else
			render json: @result, status: status if status
		end
	end

	def delete_archive
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		archive_id = params[:id]

		errors = Array.new
      @result = Hash.new
		ok = false

		if !archive_id
         errors.push(Array.new([2119, "Missing field: archive_id"]))
         status = 400
      end
		
		if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
		end

		if errors.length == 0
			jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
			end

			if jwt_valid
				user_id = decoded_jwt[0]["user_id"]
				dev_id = decoded_jwt[0]["dev_id"]
				
				user = User.find_by_id(user_id)
	
				if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
				else
					dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
						else
							archive = Archive.find_by_id(archive_id)

							if !archive
								errors.push(Array.new([2810, "Resource does not exist: Archive"]))
								status = 404
							else
								# Check if the archive belongs to the user
								if archive.user != user
									errors.push(Array.new([1102, "Action not allowed"]))
									status = 403
								else
									# Delete the archive
									archive.destroy!
									@result = {}
									ok = true
								end
							end
						end
					end
				end
			end
		end

		if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
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