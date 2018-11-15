class ValidationService
	require 'jwt'
   min_username_length = 2
   max_username_length = 25
   min_password_length = 7
	max_password_length = 25
	max_archive_count = 10
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
		app.dev != dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_table_belongs_to_app(table, app)
		error_code = 1102
		table.app != app ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_dev_is_first_dev(dev)
		error_code = 1102
		dev != Dev.first ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_users_dev_is_dev(user, dev, error_code = 1102)
		user.dev != dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_user_is_user(user1, user2)
		error_code = 1102
		user1 != user2 ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev(user, dev, app)
		error_code = 1102
		!((dev == Dev.first) && (app.dev == user.dev)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app)
		error_code = 1102
		# (Dev is first dev and the user is the dev of the app) or (Dev is user and dev and app belongs to dev)
		# Only the dev of the app can call this
		!(((dev == Dev.first) && (app.dev == user.dev)) || (user.dev == dev) && (app.dev == dev)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app)
		error_code = 1102
		# (Dev is first dev and the user is the dev of the app) or (app belongs to dev)
		# Every user of the dev can call this
		!(((dev == Dev.first) && (app.dev == user.dev)) || (app.dev == dev)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_table_object_belongs_to_user(obj, user)
		error_code = 1102
		obj.user != user ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_archive_belongs_to_user(archive, user)
		error_code = 1102
		archive.user != user ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
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
		dev.apps.length != 0 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_plan_exists(plan)
		error_code = 1108
		plan != 0 && plan != 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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

	define_singleton_method :validate_max_archive_count do |user|
		error_code = 1112
		user.archives.count >= max_archive_count ? {success: false, error: [error_code, get_error_message(error_code)], status: 422} : {success: true}
	end

	def self.validate_user_is_stripe_customer(user)
		error_code = 1113
		!user.stripe_customer_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.authenticate_user(user, password)
		error_code = 1201
		!user.authenticate(password) ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
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

	def self.validate_jwt_signature(jwt)
		begin
			decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
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

	def self.validate_access_token_missing(token)
		error_code = 2117
		!token || token.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_api_key_missing(api_key)
		error_code = 2118
		!api_key || api_key.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_archive_id_missing(archive_id)
		error_code = 2119
		!archive_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_time_missing(time)
		error_code = 2121
		!time ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_username_too_short do |username|
		error_code = 2201
		username.length < min_username_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_password_too_short do |password|
		error_code = 2202
		password.length < min_password_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_too_short do |name|
		error_code = 2203
		name.length < min_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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
		value.length < min_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_username_too_long do |username|
		error_code = 2301
		username.length > max_username_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_password_too_long do |password|
		error_code = 2302
		password.length > max_password_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_too_long do |name|
		error_code = 2303
		name.length > max_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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
		value.length > max_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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

	def self.validate_payment_token_not_valid(payment_token)
		error_code = 2405

	end

	def self.validate_table_name_contains_not_allowed_characters(table_name)
		error_code = 2501
		table_name.include?(" ") ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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

	def self.validate_username_taken(username)
		error_code = 2701
		User.exists?(username: username) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
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

	def self.validate_access_token_does_not_exist(token)
		error_code = 2809
		!token ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_archive_does_not_exist(archive)
		error_code = 2810
		!archive ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_archive_part_does_not_exist(archive_part)
		error_code = 2811
		!archive_part ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_notification_does_not_exist(notification)
		error_code = 2812
		!notification ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_dev_already_exists(dev)
		error_code = 2902
		dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 409} : {success: true}
	end

	def self.validate_table_already_exists(table)
		error_code = 2904
		table ? {success: false, error: [error_code, get_error_message(error_code)], status: 409} : {success: true}
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
			"Content-type not supported"
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
		when 1112
			"You can't create more than #{max_archive_count} archives"
		when 1113
			"Please add your payment information"
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
		when 2117
			"Missing field: access_token"
		when 2118
			"Missing field: api_key"
		when 2119
			"Missing field: archive_id"
		when 2120
			"Missing field: payment_token"
		when 2121
			"Missing field: time"
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
		when 2501
			"Field contains not allowed characters: table_name"
		when 2601
			"Field is empty: new_email"
		when 2602
			"Field is empty: old_email"
		when 2603
			"Field is empty: new_password"
		when 2701
			"Field already taken: username"
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
		when 2809
			"Resource does not exist: AccessToken"
		when 2810
			"Resource does not exist: Archive"
		when 2811
			"Resource does not exist: ArchivePart"
		when 2812
			"Resource does not exist: Notification"
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
		when 2909
			"Resource already exists: AccessToken"
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
            
            if new_sig == signature
               true
            else
               false
            end
         else
            false
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