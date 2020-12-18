class ValidationService
	require 'jwt'
   min_username_length = 2
   max_username_length = 25
   min_password_length = 7
	max_password_length = 25
	max_table_name_length = 100
   min_table_name_length = 2
   max_property_name_length = 100
   min_property_name_length = 1
   max_property_value_length = 65000
   min_property_value_length = 1
   max_app_name_length = 30
   min_app_name_length = 2
   max_app_desc_length = 500
	min_app_desc_length = 3
	min_event_name_length = 2
	max_event_name_length = 15
	max_event_data_length = 65000
	min_api_name_length = 5
	max_api_name_length = 100
	min_path_length = 2
	max_path_length = 200
	min_commands_length = 2
	max_commands_length = 65000
	min_message_length = 2
	max_message_length = 100
	min_api_function_name_length = 3
	max_api_function_name_length = 100
	max_params_length = 200
	min_product_image_length = 2
	max_product_image_length = 65000
	min_product_name_length = 2
	max_product_name_length = 300
	min_provider_image_length = 2
	max_provider_image_length = 65000
	min_provider_name_length = 2
	max_provider_name_length = 100
	min_exception_name_length = 3
	max_exception_name_length = 200
	min_exception_message_length = 2
	max_exception_message_length = 250
	min_stack_trace_length = 2
	max_stack_trace_length = 10000
	min_app_version_length = 2
	max_app_version_length = 100
	min_os_version_length = 2
	max_os_version_length = 200
	min_device_family_length = 2
	max_device_family_length = 200
	min_locale_length = 2
	max_locale_length = 10

	def self.get_errors_of_validations(validations)
		errors = Array.new
		validations.each do |validation|
			errors.push(validation["error"])
		end

		return errors
	end

	def self.raise_validation_error(validation)
		if !validation[:success]
			raise RuntimeError, [validation].to_json
		end
	end

	def self.raise_multiple_validation_errors(validations)
		errors = Array.new
		validations.each do |validation|
			errors.push(validation) if !validation[:success]
		end

		if errors.length > 0
			raise RuntimeError, errors.to_json
		end
	end

	def self.validate_authorization(auth)
		error_code = 1101
		if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
		!check_authorization(api_key, sig) ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
	end

	def self.get_access_not_allowed_error
		error_code = 1102
		{success: false, error: [error_code, get_error_message(error_code)], status: 403}
	end

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1102
		app.dev_id != dev.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_table_belongs_to_app(table, app)
		error_code = 1102
		table.app_id != app.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.dev_is_first_dev(dev)
		first_dev = DevMigration.first
		return first_dev.id == dev.id if !first_dev.nil?

		first_dev = Dev.first
		return first_dev.id == dev.id if !first_dev.nil?
		false
	end

	def self.validate_dev_is_first_dev(dev)
		error_code = 1102
		!dev_is_first_dev(dev) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_users_dev_is_dev(user, dev, error_code = 1102)
		user.id != dev.user_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_user_is_user(user1, user2)
		error_code = 1102
		user1.id != user2.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev(user, dev, app)
		error_code = 1102
		user_dev = DevDelegate.find_by(user_id: user.id)
		return {success: false, error: [error_code, get_error_message(error_code)], status: 403} if user_dev.nil?

		!(dev_is_first_dev(dev) && (app.dev_id == user_dev.id)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app)
		error_code = 1102
		user_dev = DevDelegate.find_by(user_id: user.id)
		return {success: false, error: [error_code, get_error_message(error_code)], status: 403} if user_dev.nil?

		# (Dev is first dev and the user is the dev of the app) or (Dev is user and dev and app belongs to dev)
		# Only the dev of the app can call this
		!((dev_is_first_dev(dev) && (app.dev_id == user_dev.id)) || (user_dev.id == dev.id) && (app.dev_id == dev.id)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app)
		error_code = 1102
		user_dev = DevDelegate.find_by(user_id: user.id)
		user_dev_id = user_dev.nil? ? -1 : user_dev.id

		# (Dev is first dev and the user is the dev of the app) or (app belongs to dev)
		# Every user of the dev can call this
		!((dev_is_first_dev(dev) && (app.dev_id == user_dev_id)) || (app.dev_id == dev.id)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_table_object_belongs_to_user(obj, user)
		error_code = 1102
		obj.user_id != user.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end
   
   def self.validate_session_belongs_to_user(session, user)
      error_code = 1102
      session.user_id != user.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
   end

	def self.validate_web_push_subscription_belongs_to_user(subscription, user)
		error_code = 1102
		subscription.user_id != user.id ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_unknown_validation_error(saved)
		error_code = 1103
		!saved ? {success: false, error: [error_code, get_error_message(error_code)], status: 500} : {success: true}
	end

	def self.parse_json(json)
		error_code = 1103
		begin
			json && json.length >= 2 ? JSON.parse(json) : Hash.new
		rescue Exception => e
			raise RuntimeError, {success: false, error: [error_code, get_error_message(error_code)], status: 500}.to_json
		end
	end

	def self.validate_content_type_json(content_type)
		error_code = 1104
		if content_type == nil
			content_type = ""
		end
		!content_type.include?("application/json") ? {success: false, error: [error_code, get_error_message(error_code)], status: 415} : {success: true}
	end

	def self.validate_content_type_is_supported(content_type)
		error_code = 1104
		content_type == "application/x-www-form-urlencoded" || content_type == nil ? {success: false, error: [error_code, get_error_message(error_code)], status: 415} : {success: true}
	end

	def self.validate_user_is_not_confirmed(user)
		error_code = 1106
		user.confirmed ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_all_apps_deleted(dev)
		error_code = 1107
		AppDelegate.where(dev_id: dev.id).length != 0 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_plan_exists(plan)
		error_code = 1108
		plan != 0 && plan != 1 && plan != 2 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_file_extension_supported(format)
		error_code = 1109
		!(format == "png" || format == "PNG" || format == "jpg" || format == "JPG" || format == "jpeg" || format == "JPEG") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_storage_space(free_storage, file_size)
		error_code = 1110
		free_storage < file_size ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.get_file_does_not_exist_error
		error_code = 1111
		{success: false, error: [error_code, get_error_message(error_code)], status: 400}
	end

	def self.validate_user_is_stripe_customer(user)
		error_code = 1113
		!user.stripe_customer_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user_has_payment_method(payment_methods)
		error_code = 1113
		payment_methods.data.size == 0 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user_is_user_of_app(users_app)
		error_code = 1114
		!users_app ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_user_is_not_stripe_customer(user)
		error_code = 1115
		user.stripe_customer_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_country_supported(country)
		error_code = 1116
		c = country.downcase
		(c != "de" && c != "at" && c != "us") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_currency_supported(currency)
		error_code = 1117
		c = currency.downcase
		(c != "eur") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user_of_table_object_is_provider(table_object)
		error_code = 1118
		provider = ProviderDelegate.find_by(user_id: table_object.user_id)
		provider.nil? ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_purchase_already_completed(purchase)
		error_code = 1119
		purchase.completed ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_table_object_already_purchased(user, table_object)
		error_code = 1121
		PurchaseDelegate.find_by(user_id: user.id, table_object_id: table_object.id, completed: true) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.authenticate_user(user, password)
		error_code = 1201
		p = BCrypt::Password.new(user.password_digest)
		p != password ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
	end

	def self.validate_user_is_confirmed(user)
		error_code = 1202
		!user.confirmed ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_password_confirmation_token_of_user(user, token)
		error_code = 1203
		user.password_confirmation_token != token ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.get_password_confirmation_token_incorrect_error(bool)
		error_code = 1203
		bool ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_email_confirmation_token_of_user(user, token)
		error_code = 1204
		user.email_confirmation_token != token ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

   def self.validate_jwt_signature(jwt, session_id = 0)
      secret = ENV['JWT_SECRET']
      if session_id != 0
         session = SessionDelegate.find_by(id: session_id)
         if !session
            # Session does not exist
            error_code = 2814
            return [{success: false, error: [error_code, get_error_message(error_code)], status: 404}]
         end

         secret = session.secret
      end

		begin
			decoded_jwt = JWT.decode jwt, secret, true, { :algorithm => ENV['JWT_ALGORITHM'] }
			[{success: true}, decoded_jwt]
		rescue JWT::ExpiredSignature
			# JWT expired
			error_code = 1301
			[{success: false, error: [error_code, get_error_message(error_code)], status: 401}]
		rescue JWT::DecodeError
			error_code = 1302
			[{success: false, error: [error_code, get_error_message(error_code)], status: 401}]
		rescue Exception
			error_code = 1303
			[{success: false, error: [error_code, get_error_message(error_code)], status: 401}]
		end
   end

	def self.validate_auth_missing(auth)
		error_code = 2101
		!auth || auth.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
	end

	def self.validate_jwt_missing(jwt)
		error_code = 2102
		!jwt || jwt.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
	end

	def self.validate_id_missing(id)
		error_code = 2103
		!id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user_id_missing(user_id)
		error_code = 2104
		!user_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_username_missing(username)
		error_code = 2105
		!username || username.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_email_missing(email)
		error_code = 2106
		!email || email.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_password_missing(password)
		error_code = 2107
		!password || password.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_email_confirmation_token_missing(token)
		error_code = 2108
		!token || token.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_password_confirmation_token_missing(token)
		error_code = 2109
		!token || token.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_app_id_missing(app_id)
		error_code = 2110
		!app_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_name_missing(name)
		error_code = 2111
		!name || name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_desc_missing(desc)
		error_code = 2112
		!desc || desc.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_table_name_missing(table_name)
		error_code = 2113
		!table_name || table_name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_table_name_and_table_id_missing(table_name, table_id)
		# Prefer table_name over table_id; if table_name and table_id is missing, return that table_name is missing
		error_code = 2113
		((!table_name || table_name.length < 1) && !table_id) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_object_missing(object)
		error_code = 2116
		object.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_api_key_missing(api_key)
		error_code = 2118
		!api_key || api_key.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_time_missing(time)
		error_code = 2121
		!time ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_endpoint_missing(endpoint)
		error_code = 2122
		!endpoint || endpoint.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_p256dh_missing(p256dh)
		error_code = 2123
		!p256dh || p256dh.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_subscription_auth_missing(auth)
		error_code = 2101
		!auth || auth.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_uuid_missing(uuid)
		error_code = 2124
		!uuid || uuid.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
   end
   
   def self.validate_device_name_missing(device_name)
      error_code = 2125
      !device_name || device_name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
   end

   def self.validate_device_type_missing(device_type)
      error_code = 2126
      !device_type || device_type.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
   end

   def self.validate_device_os_missing(device_os)
      error_code = 2127
      !device_os || device_os.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end
	
	def self.validate_browser_name_missing(browser_name)
		error_code = 2128
		!browser_name || browser_name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_browser_version_missing(browser_version)
		error_code = 2129
		!browser_version || browser_version.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_os_name_missing(os_name)
		error_code = 2130
		!os_name || os_name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_os_version_missing(os_version)
		error_code = 2131
		!os_version || os_version.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_path_missing(path)
		error_code = 2132
		!path || path.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_method_missing(method)
		error_code = 2133
		!method || method.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_commands_missing(commands)
		error_code = 2134
		!commands || commands.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_code_missing(code)
		error_code = 2135
		!code ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_message_missing(message)
		error_code = 2136
		!message || message.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end
	
	def self.validate_errors_missing(errors)
		error_code = 2137
		!errors ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_country_missing(country)
		error_code = 2138
		!country ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_price_missing(price)
		error_code = 2139
		!price ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_currency_missing(currency)
		error_code = 2140
		!currency ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_product_image_missing(product_image)
		error_code = 2141
		!product_image ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_product_name_missing(product_name)
		error_code = 2142
		!product_name ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_provider_image_missing(provider_image)
		error_code = 2143
		!provider_image ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_provider_name_missing(provider_name)
		error_code = 2144
		!provider_name ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_stack_trace_missing(stack_trace)
		error_code = 2145
		!stack_trace ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_app_version_missing(app_version)
		error_code = 2146
		!app_version ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_device_family_missing(device_family)
		error_code = 2147
		!device_family ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_locale_missing(locale)
		error_code = 2148
		!locale ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_username_too_short do |username|
		error_code = 2201
		username.length < min_username_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_password_too_short do |password|
		error_code = 2202
		password.length < min_password_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_event_too_short do |name|
		error_code = 2203
		name.length < min_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_app_too_short do |name|
		error_code = 2203
		name.length < min_app_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_table_too_short do |name|
		error_code = 2203
		name.length < min_table_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_api_too_short do |name|
		error_code = 2203
		name.length < min_api_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_api_function_too_short do |name|
		error_code = 2203
		name.length < min_api_function_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_exception_too_short do |name|
		error_code = 2203
		name.length < min_exception_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_desc_too_short do |desc|
		error_code = 2204
		desc.length < min_app_desc_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_table_name_too_short do |table_name|
		error_code = 2205
		table_name.length < min_table_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_name_too_short do |name|
		error_code = 2206
		name.length < min_property_name_length ? {success: false, error: Array.new([error_code, get_error_message(error_code)]), status: 400} : {success: true}
	end

	define_singleton_method :validate_property_value_too_short do |value|
		error_code = 2207
		value.to_s.length < min_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_path_too_short do |path|
		error_code = 2208
		path.length < min_path_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_commands_too_short do |commands|
		error_code = 2209
		commands.length < min_commands_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_message_too_short do |message|
		error_code = 2210
		message.length < min_message_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_message_for_exception_too_short do |message|
		error_code = 2210
		message.length < min_exception_message_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_product_image_too_short do |product_image|
		error_code = 2211
		product_image.length < min_product_image_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_product_name_too_short do |product_name|
		error_code = 2212
		product_name.length < min_product_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_provider_image_too_short do |provider_image|
		error_code = 2213
		provider_image.length < min_provider_image_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_provider_name_too_short do |provider_name|
		error_code = 2214
		provider_name.length < min_provider_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_stack_trace_too_short do |stack_trace|
		error_code = 2215
		stack_trace.length < min_stack_trace_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_app_version_too_short do |app_version|
		error_code = 2216
		app_version.length < min_app_version_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_os_version_too_short do |os_version|
		error_code = 2217
		os_version.length < min_os_version_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_device_family_too_short do |device_family|
		error_code = 2218
		device_family.length < min_device_family_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_locale_too_short do |locale|
		error_code = 2219
		locale.length < min_locale_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_username_too_long do |username|
		error_code = 2301
		username.length > max_username_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_password_too_long do |password|
		error_code = 2302
		password.length > max_password_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_event_too_long do |name|
		error_code = 2303
		name.length > max_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_app_too_long do |name|
		error_code = 2303
		name.length > max_app_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_table_too_long do |name|
		error_code = 2303
		name.length > max_table_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_api_too_long do |name|
		error_code = 2303
		name.length > max_api_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_api_function_too_long do |name|
		error_code = 2303
		name.length > max_api_function_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_for_exception_too_long do |name|
		error_code = 2303
		name.length > max_exception_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_desc_too_long do |desc|
		error_code = 2304
		desc.length > max_app_desc_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_table_name_too_long do |table_name|
		error_code = 2305
		table_name.length > max_table_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_name_too_long do |name|
		error_code = 2306
		name.length > max_property_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_value_too_long do |value|
		error_code = 2307
		value.to_s.length > max_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_path_too_long do |path|
		error_code = 2308
		path.length > max_path_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_commands_too_long do |commands|
		error_code = 2309
		commands.length > max_commands_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_message_too_long do |message|
		error_code = 2310
		message.length > max_message_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_message_for_exception_too_long do |message|
		error_code = 2310
		message.length > max_exception_message_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_params_too_long do |params|
		error_code = 2311
		params.length > max_message_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_product_image_too_long do |product_image|
		error_code = 2312
		product_image.length > max_product_image_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_product_name_too_long do |product_name|
		error_code = 2313
		product_name.length > max_product_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_provider_image_too_long do |provider_image|
		error_code = 2314
		provider_image.length > max_provider_image_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_provider_name_too_long do |provider_name|
		error_code = 2315
		provider_name.length > max_provider_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_stack_trace_too_long do |stack_trace|
		error_code = 2316
		stack_trace.length > max_stack_trace_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_app_version_too_long do |app_version|
		error_code = 2317
		app_version.length > max_app_version_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_os_version_too_long do |os_version|
		error_code = 2318
		os_version.length > max_os_version_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_device_family_too_long do |device_family|
		error_code = 2319
		device_family.length > max_device_family_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_locale_too_long do |locale|
		error_code = 2320
		locale.length > max_locale_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_email_not_valid(email)
		error_code = 2401
		!validate_email(email) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_web_not_valid(link)
		error_code = 2402
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_play_not_valid(link)
		error_code = 2403
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_windows_not_valid(link)
		error_code = 2404
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.get_payment_token_not_valid_error
		error_code = 2405
		{success: false, error: [error_code, get_error_message(error_code)], status: 400}
	end

	def self.validate_method_not_valid(method)
		error_code = 2406
		!["get", "post", "put", "delete"].include?(method.downcase) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_code_not_valid(code)
		error_code = 2407
		(!code.is_a?(Integer) || code < 0) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_price_not_valid(price)
		error_code = 2408
		(!price.is_a?(Integer) || price < 0) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_table_name_contains_not_allowed_characters(table_name)
		error_code = 2501
		table_name.include?(" ") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_name_contains_not_allowed_characters(name)
		error_code = 2502
		name.include?(" ") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_new_email_empty(new_email)
		error_code = 2601
		new_email == nil || new_email.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_old_email_empty(old_email)
		error_code = 2602
		old_email == nil || old_email.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_new_password_empty(new_password)
		error_code = 2603
		new_password == nil || new_password.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_email_taken(email)
		error_code = 2702
		User.exists?(email: email) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_event_name_taken(new_name, old_name, app_id)
		error_code = 2703
		Event.exists?(name: new_name, app_id: app_id) && old_name != new_name ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_table_object_uuid_taken(uuid)
		error_code = 2704
		TableObject.exists?(uuid: uuid) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_subscription_uuid_taken(uuid)
		error_code = 2704
		WebPushSubscription.exists?(uuid: uuid) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_notification_uuid_taken(uuid)
		error_code = 2704
		Notification.exists?(uuid: uuid) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user_does_not_exist(user)
		error_code = 2801
		!user ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_dev_does_not_exist(dev)
		error_code = 2802
		!dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_app_does_not_exist(app)
		error_code = 2803
		!app ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_table_does_not_exist(table)
		error_code = 2804
		!table ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_table_object_does_not_exist(table_object)
		error_code = 2805
		!table_object ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_event_does_not_exist(event)
		error_code = 2807
		!event ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_notification_does_not_exist(notification)
		error_code = 2812
		!notification ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_web_push_subscription_does_not_exist(subscription)
		error_code = 2813
		!subscription ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
   end
   
   def self.validate_session_does_not_exist(session)
		error_code = 2814
		!session ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end
	
	def self.validate_api_does_not_exist(api)
		error_code = 2815
		!api ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_api_endpoint_does_not_exist(api_endpoint)
		error_code = 2816
		!api_endpoint ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_provider_does_not_exist(provider)
		error_code = 2817
		!provider ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_purchase_does_not_exist(purchase)
		error_code = 2818
		!purchase ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_table_object_user_access_does_not_exist(access)
		error_code = 2819
		!access ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_dev_already_exists(dev)
		error_code = 2902
		dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 409} : {success: true}
	end

	def self.validate_table_already_exists(table)
		error_code = 2904
		table ? {success: false, error: [error_code, get_error_message(error_code)], status: 409} : {success: true}
	end

	def self.validate_provider_already_exists(provider)
		error_code = 2910
		provider ? {success: false, error: [error_code, get_error_message(error_code)], status: 409} : {success: true}
	end

	define_singleton_method :get_error_message do |code|
		case code
		when 1101
			"Authentication failed"
		when 1102
			"Action not allowed"
		when 1103
			"Unknown validation error"
		when 1104
			"Content-Type not supported"
		when 1105
			"User is not confirmed"
		when 1106
			"User is already confirmed"
		when 1107
			"All Apps need to be deleted"
		when 1108
			"Plan does not exist"
		when 1109
			"File extension not supported"
		when 1110
			"Not enough storage space"
		when 1111
			"File does not exist"
		when 1113
			"Please add your payment information"
		when 1114
			"The User is not a user of this app"
		when 1115
			"User is already a stripe customer"
		when 1116
			"Country not supported"
		when 1117
			"Currency not supported"
		when 1118
			"User of TableObject is not a provider"
		when 1119
			"Purchase is already completed"
		when 1121
			"You already purchased this TableObject"
		when 1201
			"Password is incorrect"
		when 1202
			"User is not confirmed"
		when 1203
			"Password confirmation token is not correct"
		when 1204
			"Email confirmation token is not correct"
		when 1301
			"JWT expired"
		when 1302
			"JWT not valid"
		when 1303
			"JWT unknown error"
		when 2101
			"Missing field: auth"
		when 2102
			"Missing field: jwt"
		when 2103
			"Missing field: id"
		when 2104
			"Missing field: user_id"
		when 2105
			"Missing field: username"
		when 2106
			"Missing field: email"
		when 2107
			"Missing field: password"
		when 2108
			"Missing field: email_confirmation_token"
		when 2109
			"Missing field: password_confirmation_token"
		when 2110
			"Missing field: app_id"
		when 2111
			"Missing field: name"
		when 2112
			"Missing field: description"
		when 2113
			"Missing field: table_name"
		when 2114
			"Missing field: table_id"
		when 2115
			"Missing field: object_id"
		when 2116
			"Missing field: object"
		when 2118
			"Missing field: api_key"
		when 2120
			"Missing field: payment_token"
		when 2121
			"Missing field: time"
		when 2122
			"Missing field: endpoint"
		when 2123
			"Missing field: p256dh"
		when 2124
         "Missing field: uuid"
      when 2125
         "Missing field: device_name"
      when 2126
         "Missing field: device_type"
      when 2127
			"Missing field: device_os"
		when 2128
			"Missing field: browser_name"
		when 2129
			"Missing field: browser_version"
		when 2130
			"Missing field: os_name"
		when 2131
			"Missing field: os_version"
		when 2132
			"Missing field: path"
		when 2133
			"Missing field: method"
		when 2134
			"Missing field: commands"
		when 2135
			"Missing field: code"
		when 2136
			"Missing field: message"
		when 2137
			"Missing field: errors"
		when 2138
			"Missing field: country"
		when 2139
			"Missing field: price"
		when 2140
			"Missing field: currency"
		when 2141
			"Missing field: product_image"
		when 2142
			"Missing field: product_name"
		when 2143
			"Missing field: provider_image"
		when 2144
			"Missing field: provider_name"
		when 2145
			"Missing field: stack_trace"
		when 2146
			"Missing field: app_version"
		when 2147
			"Missing field: device_family"
		when 2148
			"Missing field: locale"
		when 2201
			"Field too short: username"
		when 2202
			"Field too short: password"
		when 2203
			"Field too short: name"
		when 2204
			"Field too short: description"
		when 2205
			"Field too short: table_name"
		when 2206
			"Field too short: Property.name"
		when 2207
			"Field too short: Property.value"
		when 2208
			"Field too short: path"
		when 2209
			"Field too short: commands"
		when 2210
			"Field too short: message"
		when 2211
			"Field too short: product_image"
		when 2212
			"Field too short: product_name"
		when 2213
			"Field too short: provider_image"
		when 2214
			"Field too short: provider_name"
		when 2215
			"Field too short: stack_trace"
		when 2216
			"Field too short: app_version"
		when 2217
			"Field too short: os_version"
		when 2218
			"Field too short: device_family"
		when 2219
			"Field too short: locale"
		when 2301
			"Field too long: username"
		when 2302
			"Field too long: password"
		when 2303
			"Field too long: name"
		when 2304
			"Field too long: description"
		when 2305
			"Field too long: table_name"
		when 2306
			"Field too long: Property.name"
		when 2307
			"Field too long: Property.value"
		when 2308
			"Field too long: path"
		when 2309
			"Field too long: commands"
		when 2310
			"Field too long: message"
		when 2311
			"Field too long: params"
		when 2312
			"Field too long: product_image"
		when 2313
			"Field too long: product_name"
		when 2314
			"Field too long: provider_image"
		when 2315
			"Field too long: provider_name"
		when 2316
			"Field too long: stack_trace"
		when 2317
			"Field too long: app_version"
		when 2318
			"Field too long: os_version"
		when 2319
			"Field too long: device_family"
		when 2320
			"Field too long: locale"
		when 2401
			"Field not valid: email"
		when 2402
			"Field not valid: link_web"
		when 2403
			"Field not valid: link_play"
		when 2404
			"Field not valid: link_windows"
		when 2405
			"Field not valid: payment_token"
		when 2406
			"Field not valid: method"
		when 2407
			"Field not valid: code"
		when 2408
			"Field not valid: price"
		when 2501
			"Field contains not allowed characters: table_name"
		when 2502
			"Field contains not allowed characters: name"
		when 2601
			"Field is empty: new_email"
		when 2602
			"Field is empty: old_email"
		when 2603
			"Field is empty: new_password"
		when 2702
			"Field already taken: email"
		when 2703
			"Field already taken: name"
		when 2704
			"Field already taken: uuid"
		when 2801
			"Resource does not exist: User"
		when 2802
			"Resource does not exist: Dev"
		when 2803
			"Resource does not exist: App"
		when 2804
			"Resource does not exist: Table"
		when 2805
			"Resource does not exist: TableObject"
		when 2806
			"Resource does not exist: Property"
		when 2807
			"Resource does not exist: Event"
		when 2808
			"Resource does not exist: EventLog"
		when 2812
			"Resource does not exist: Notification"
		when 2813
			"Resource does not exist: WebPushSubscription"
		when 2814
			"Resource does not exist: Session"
		when 2815
			"Resource does not exist: Api"
		when 2816
			"Resource does not exist: ApiEndpoint"
		when 2817
			"Resource does not exist: Provider"
		when 2818
			"Resource does not exist: Purchase"
		when 2819
			"Resource does not exist: TableObjectUserAccess"
		when 2901
			"Resource already exists: User"
		when 2902
			"Resource already exists: Dev"
		when 2903
			"Resource already exists: App"
		when 2904
			"Resource already exists: Table"
		when 2905
			"Resource already exists: TableObject"
		when 2906
			"Resource already exists: Property"
		when 2907
			"Resource already exists: Event"
		when 2908
			"Resource already exists: EventLog"
		when 2910
			"Resource already exists: Provider"
		else
			raise RuntimeError, "The error code #{code} does not exist!"
		end
	end

	def self.check_authorization(api_key, signature)
      dev = Dev.find_by(api_key: api_key)
      
      if !dev
         false
      else
         if api_key == dev.api_key
            new_sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
            return new_sig == signature
         else
            return false
         end
      end
	end

	def self.validate_url(url)
      /\A#{URI::regexp}\z/.match?(url)
	end
	
	def self.validate_email(email)
      reg = Regexp.new("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      return (reg.match(email))? true : false
   end
end