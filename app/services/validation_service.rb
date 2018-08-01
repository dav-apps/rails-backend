class ValidationService
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

	def self.validate_app_belongs_to_dev(app, dev)
		error_code = 1102
		app.dev != dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_dev_is_first_dev(dev)
		error_code = 1102
		dev != Dev.first ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_users_dev_is_dev(user, dev)
		error_code = 1102
		user.dev != dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev(user, dev, app)
		error_code = 1102
		!((dev == Dev.first) && (app.dev == user.dev)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
	end

	def self.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app)
		error_code = 1102
		!(((dev == Dev.first) && (app.dev == user.dev)) || user.dev == dev) ? {success: false, error: [error_code, get_error_message(error_code)], status: 403} : {success: true}
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

	def self.validate_content_type(content_type)
		error_code = 1104
		if content_type == nil
			content_type = ""
		end
		!content_type.include?("application/json") ? {success: false, error: [error_code, get_error_message(error_code)], status: 415} : {success: true}
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

	def self.validate_jwt(jwt)
		error_code = 2102
		!jwt || jwt.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 401} : {success: true}
	end

	def self.validate_id(id)
		error_code = 2103
		!id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_app_id(app_id)
		error_code = 2110
		!app_id ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_name(name)
		error_code = 2111
		!name || name.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_desc(desc)
		error_code = 2112
		!desc || desc.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_api_key(api_key)
		error_code = 2118
		!api_key || api_key.length < 1 ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_too_short do |name|
		error_code = 2203
		name.length < min_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_desc_too_short do |desc|
		error_code = 2204
		desc.length < min_app_desc_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_name_too_short do |name|
		error_code = 2206
		name.length < min_property_name_length ? {success: false, error: Array.new([error_code, get_error_message(error_code)]), status: 400} : {success: true}
	end

	define_singleton_method :validate_property_value_too_short do |value|
		error_code = 2207
		value.length < min_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_name_too_long do |name|
		error_code = 2303
		name.length > max_event_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_desc_too_long do |desc|
		error_code = 2304
		desc.length > max_app_desc_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_name_too_long do |name|
		error_code = 2306
		name.length > max_property_name_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	define_singleton_method :validate_property_value_too_long do |value|
		error_code = 2307
		value.length > max_property_value_length ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_web(link)
		error_code = 2402
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_play(link)
		error_code = 2403
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_link_windows(link)
		error_code = 2404
		!(link.length == 0 || validate_url(link)) ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_event_name_taken(new_name, old_name, app_id)
		error_code = 2703
		Event.exists?(name: new_name, app_id: app_id) && old_name != new_name ? {success: false, error: [error_code, get_error_message(error_code)], status: 400} : {success: true}
	end

	def self.validate_user(user)
		error_code = 2801
		!user ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_dev(dev)
		error_code = 2802
		!dev ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_app(app)
		error_code = 2803
		!app ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.validate_event(event)
		error_code = 2807
		!event ? {success: false, error: [error_code, get_error_message(error_code)], status: 404} : {success: true}
	end

	def self.get_error_message(code)
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
			"You can't create more than 10 archives"
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

	def self.validate_url(url)
      /\A#{URI::regexp}\z/.match?(url)
   end
end