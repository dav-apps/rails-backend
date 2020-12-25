class AppsController < ApplicationController
	# App methods
	def create_app
		jwt, session_id = get_jwt_from_header(get_authorization_header)

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)
			name = body["name"]
			description = body["description"]
			link_web = body["link_web"]
			link_play = body["link_play"]
			link_windows = body["link_windows"]

			# Make sure name and description are present
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_missing(name),
            ValidationService.validate_desc_missing(description)
			])

			# Validate name and description
         ValidationService.raise_multiple_validation_errors([
            ValidationService.validate_name_for_app_too_short(name),
            ValidationService.validate_name_for_app_too_long(name),
            ValidationService.validate_desc_too_short(description),
            ValidationService.validate_desc_too_long(description)
         ])

			# Validate the links
         validations = Array.new

			validations.push(ValidationService.validate_link_web_not_valid(link_web)) if link_web
			validations.push(ValidationService.validate_link_play_not_valid(link_play)) if link_play
			validations.push(ValidationService.validate_link_windows_not_valid(link_windows)) if link_windows
         
			ValidationService.raise_multiple_validation_errors(validations)
			
			# Create the app
			app = AppDelegate.new(name: name, description: description, dev_id: DevDelegate.find_by(user_id: user.id).id)

			app.link_web = link_web if link_web
			app.link_play = link_play if link_play
			app.link_windows = link_windows if link_windows

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(app.save))
			render json: app.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	
	def get_app
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(app_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website or from the associated dev
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app))

			# Return the data
			tables = Array.new
			TableDelegate.where(app_id: app.id).each do |table|
				tables.push(table)
			end
			
			events = Array.new
			Event.where(app_id: app.id).each do |event|
				events.push(event)
			end

			apis = Array.new
			ApiDelegate.where(app_id: app.id).each do |api|
				apis.push(api)
			end
			
			result = app.attributes
			result["tables"] = tables
			result["events"] = events
			result["apis"] = apis
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_active_app_users
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		id = params["id"]
		start_timestamp = params["start"] ? DateTime.strptime(params["start"],'%s').beginning_of_day : (Time.now - 1.month).beginning_of_day
		end_timestamp = params["end"] ? DateTime.strptime(params["end"],'%s').beginning_of_day : Time.now.beginning_of_day

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

			app = AppDelegate.find_by(id: id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			days = Array.new
			ActiveAppUserDelegate.where("app_id = ? AND time >= ? AND time <= ?", app.id, start_timestamp, end_timestamp).each do |active_user|
				days.push({
					time: active_user.time.to_s,
					count_daily: active_user.count_daily,
					count_monthly: active_user.count_monthly,
					count_yearly: active_user.count_yearly
				})
			end

			render json: {days: days}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_all_apps
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))

			api_key = auth.split(",")[0]
         sig = auth.split(",")[1]

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get all apps and return them
			apps = App.all
			apps_array = Array.new

			apps.each do |app|
				if app.published
					apps_array.push(app.attributes)
				end
			end

			result = Hash.new
			result["apps"] = apps_array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def update_app
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(app_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			object = ValidationService.parse_json(request.body.string)
			validations = Array.new

			name = object["name"]
			if name
				validations.push(
					ValidationService.validate_name_for_app_too_short(name), 
					ValidationService.validate_name_for_app_too_long(name)
				)

				app.name = name
			end

			desc = object["description"]
			if desc
				validations.push(
					ValidationService.validate_desc_too_short(desc),
					ValidationService.validate_desc_too_long(desc)
				)

				app.description = desc
			end

			published = object["published"]
			# Check if published is given and if it's a boolean
			if !!published == published
				app.published = published
			end

			link_web = object["link_web"]
			if link_web
				validations.push(ValidationService.validate_link_web_not_valid(link_web))
				app.link_web = link_web
			end

			link_play = object["link_play"]
			if link_play
				validations.push(ValidationService.validate_link_play_not_valid(link_play))
				app.link_play = link_play
			end

			link_windows = object["link_windows"]
			if link_windows
				validations.push(ValidationService.validate_link_windows_not_valid(link_windows))
				app.link_windows = link_windows
			end
			
			ValidationService.raise_multiple_validation_errors(validations)

			# Update the app
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(app.save))
			result = app
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_app
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(app_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			app.destroy
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	# ExceptionEvent methods
	def create_exception_event
		app_id = params["id"]

		begin
			# Validate content type json
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			# Validate the app
			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)
			api_key = body["api_key"]
			name = body["name"]
			message = body["message"]
			stack_trace = body["stack_trace"]
			app_version = body["app_version"]
			os_version = body["os_version"]
			device_family = body["device_family"]
			locale = body["locale"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_api_key_missing(api_key),
				ValidationService.validate_name_missing(name),
				ValidationService.validate_message_missing(message),
				ValidationService.validate_stack_trace_missing(stack_trace),
				ValidationService.validate_app_version_missing(app_version),
				ValidationService.validate_os_version_missing(os_version),
				ValidationService.validate_device_family_missing(device_family),
				ValidationService.validate_locale_missing(locale)
			])

			# Validate the dev
			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# Validate the length of the params
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_for_exception_too_short(name),
				ValidationService.validate_name_for_exception_too_long(name),
				ValidationService.validate_message_for_exception_too_short(message),
				ValidationService.validate_message_for_exception_too_long(message),
				ValidationService.validate_stack_trace_too_short(stack_trace),
				ValidationService.validate_stack_trace_too_long(stack_trace),
				ValidationService.validate_app_version_too_short(app_version),
				ValidationService.validate_app_version_too_long(app_version),
				ValidationService.validate_os_version_too_short(os_version),
				ValidationService.validate_os_version_too_long(os_version),
				ValidationService.validate_device_family_too_short(device_family),
				ValidationService.validate_device_family_too_long(device_family),
				ValidationService.validate_locale_too_short(locale),
				ValidationService.validate_locale_too_long(locale)
			])

			# Create the exception event
			exception = ExceptionEventDelegate.new(
				app_id: app.id,
				name: name,
				message: message,
				stack_trace: stack_trace,
				app_version: app_version,
				os_version: os_version,
				device_family: device_family,
				locale: locale
			)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(exception.save))

			# Return the data
			render json: exception, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
   
	# TableObject methods
   def create_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		table_name = params["table_name"]
		table_id = params["table_id"]
      app_id = params["app_id"]
		ext = params["ext"]
		uuid = params["uuid"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_table_name_and_table_id_missing(table_name, table_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if table_id
				table = TableDelegate.find_by(id: table_id)
			elsif table_name
				table = TableDelegate.find_by(name: table_name, app_id: app_id)

				if !table
					# If the dev is not logged in, return 2804: Resource does not exist: Table
					ValidationService.raise_validation_error(ValidationService.validate_users_dev_is_dev(user, dev, 2804))

					# Validate the table name
					ValidationService.raise_multiple_validation_errors([
						ValidationService.validate_table_name_too_short(table_name),
						ValidationService.validate_table_name_too_long(table_name),
						ValidationService.validate_table_name_contains_not_allowed_characters(table_name)
					])

					# Create the table
					table = TableDelegate.new(app_id: app.id, name: (table_name[0].upcase + table_name[1..-1]))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))
				end
			end

			# Check if the table exists
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			# Check if the table belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_table_belongs_to_app(table, app))

			if uuid
				# Check if the uuid is already in use
				ValidationService.raise_validation_error(ValidationService.validate_table_object_uuid_taken(uuid))
			end

			type = get_content_type_header
         ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(type))

			obj = TableObjectDelegate.new(table_id: table.id, user_id: user.id)

			if uuid
				obj.uuid = uuid
			else
				obj.uuid = SecureRandom.uuid
			end

			# If there is an ext property, save object as a file
			if !ext || ext.length < 1
				# Save the object normally
				obj.file = false

				# Content-Type must be application/json
				ValidationService.raise_validation_error(ValidationService.validate_content_type_json(type))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				object = ValidationService.parse_json(request.body.string)
				ValidationService.raise_validation_error(ValidationService.validate_object_missing(object))

				object.each do |key, value|
					next if value == nil || value.to_s.length == 0

					ValidationService.raise_multiple_validation_errors([
						ValidationService.validate_property_name_too_short(key),
						ValidationService.validate_property_name_too_long(key),
						ValidationService.validate_property_value_too_short(value),
						ValidationService.validate_property_value_too_long(value)
					])
				end

				properties = Hash.new
				
				object.each do |name, value|
					next if value == nil || value.to_s.length == 0

					create_property_type(table, name, value)

					property = PropertyDelegate.new(table_object_id: obj.id, name: name, value: value.to_s)
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(property.save))

					properties[name] = value
				end

				# Generate the etag
				obj.etag = generate_table_object_etag(obj)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				# Save that user uses the app
				users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
				if !users_app
					users_app = UsersAppDelegate.new(app_id: app.id, user_id: user.id)
					users_app.save
				end

				# Save that the user was active
				user.last_active = Time.now
				user.save

				users_app.last_active = Time.now
				users_app.save

				# Notify connected clients of the new object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 0, session_id: session_id)

				# Return the data
				result = obj.attributes
				result["properties"] = properties
				result["etag"] = obj.etag

				render json: result, status: 201
			else
				# Save the object as a file
				# Check if the user has enough free storage
				file_size = get_file_size(request.body)
				free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage
				obj.file = true

				ValidationService.raise_validation_error(ValidationService.validate_storage_space(free_storage, file_size))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				begin
					blob = BlobOperationsService.upload_blob(app.id, obj.id, request.body)
					etag = blob.properties[:etag]

					# Remove the first and the last character of etag, because they are "" for whatever reason
					etag = etag[1...etag.size-1]

					# Save extension as property
					ext_prop = PropertyDelegate.new(table_object_id: obj.id, name: "ext", value: ext)

					# Save etag as property
					etag_prop = PropertyDelegate.new(table_object_id: obj.id, name: "etag", value: etag)

					# Save the file size as property
					size_prop = PropertyDelegate.new(table_object_id: obj.id, name: "size", value: file_size)
					
					# Save the content type as property
               type_prop = PropertyDelegate.new(table_object_id: obj.id, name: "type", value: type)

					# Update the used storage
					UtilsService.update_used_storage(user, app, file_size)

					# Save that user uses the app
					users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
					if !users_app
						users_app = UsersAppDelegate.new(app_id: app.id, user_id: user.id)
						users_app.save
					end

					# Create the properties
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(ext_prop.save))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(etag_prop.save))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(size_prop.save))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(type_prop.save))

					# Return the data
					result = obj.attributes

					properties = Hash.new
					PropertyDelegate.where(table_object_id: obj.id).each do |prop|
						properties[prop.name] = prop.value
					end

					# Generate the etag
					obj.etag = generate_table_object_etag(obj)
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

					# Save that the user was active
					user.last_active = Time.now
					user.save

					users_app.last_active = Time.now
					users_app.save

					# Notify connected clients of the new object
					TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 0, session_id: session_id)

					result["properties"] = properties
					result["etag"] = obj.etag
					render json: result, status: 201
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(false))
				end
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		object_id = params["id"]
		token = params["access_token"]
		file = params["file"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(object_id)
			])

			if object_id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: object_id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: object_id.to_i)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = TableDelegate.find_by(id: obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			can_access = false
			table_id = obj.table_id

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# Check if there is a TableObjectUserAccess
			user_access = TableObjectUserAccessDelegate.find_by(user_id: user.id, table_object_id: obj.id)

			if !user_access
				ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))
			end

			if user_access
				table_id = user_access.table_alias
			end

			# Save that the user was active
			user.last_active = Time.now
			user.save

			users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
			if !users_app.nil?
				users_app.last_active = Time.now
				users_app.save
			end

			if file == "true" && obj.file
				# Return the file of the object
				Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
				Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
				filename = "#{app.id}/#{obj.id}"
				type = "application/octet-stream"

				begin
					client = Azure::Blob::BlobService.new
					blob = client.get_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename)

					result = blob[1]

					# Get the file extension and content type
					PropertyDelegate.where(table_object_id: obj.id).each do |prop|
						if prop.name == "ext"
							filename += ".#{prop.value}"
						elsif prop.name == "type"
							type = prop.value
						end
					end
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.get_file_does_not_exist_error)
				end

				response.headers['Content-Length'] = result.size.to_s
				send_data(result, status: 200, type: type, filename: filename)
			else
				# Generate the etag if the table object has none
				if obj.etag.nil?
					obj.etag = generate_table_object_etag(obj)
					obj.save
				end

				# Return the object data
				result = obj.attributes
				property_types = PropertyTypeDelegate.where(table_id: table.id)
				properties = Hash.new

				PropertyDelegate.where(table_object_id: obj.id).each do |prop|
					# Get the data type and convert the value
					properties[prop.name] = convert_value_to_data_type(prop.value, find_data_type(property_types, prop.name))
				end

				result["properties"] = properties
				result["etag"] = obj.etag
				result["table_id"] = table_id

				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
   end
   
   def get_object_with_auth
      auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		id = params["id"]
		file = params["file"]

		begin
			# Validate the auth
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))

			api_key, sig = auth.split(',')

			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			if id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: id.to_i)
			end

         ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

         table = TableDelegate.find_by(id: obj.table_id)
         ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))
         
         app = AppDelegate.find_by(id: table.app_id)
         ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
         
			# Check if the object belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if file == "true" && obj.file
				# Return the file of the object
				Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
				Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
				filename = "#{app.id}/#{obj.id}"
				type = "application/octet-stream"

				begin
					client = Azure::Blob::BlobService.new
					blob = client.get_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename)

					result = blob[1]

					# Get the file extension and content type
					PropertyDelegate.where(table_object_id: obj.id).each do |prop|
						if prop.name == "ext"
							filename += ".#{prop.value}"
						elsif prop.name == "type"
							type = prop.value
						end
					end
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.get_file_does_not_exist_error)
				end

				response.headers['Content-Length'] = result.size.to_s
				send_data(result, status: 200, type: type, filename: filename)
			else
				# Generate the etag if the table object has none
				if obj.etag.nil?
					obj.etag = generate_table_object_etag(obj)
					obj.save
				end

				# Return the data
				result = obj.attributes
				property_types = PropertyTypeDelegate.where(table_id: table.id)
				properties = Hash.new

				PropertyDelegate.where(table_object_id: obj.id).each do |prop|
					# Get the data type and convert the value
					properties[prop.name] = convert_value_to_data_type(prop.value, find_data_type(property_types, prop.name))
				end

				result["properties"] = properties
				result["etag"] = obj.etag

				render json: result, status: 200
			end
      rescue => e
         validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
      end
   end
	
	def update_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		object_id = params["id"]
		ext = params["ext"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(object_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			if object_id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: object_id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: object_id.to_i)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))
			
			table = TableDelegate.find_by(id: obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			type = get_content_type_header
			ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(type))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))

			if obj.file
				if ext && ext.length > 0
					# Update the ext property
					ext_prop = PropertyDelegate.find_by(table_object_id: obj.id, name: "ext")
					ext_prop.value = ext
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(ext_prop.save))
				end

				# Update the type property
				type_prop = PropertyDelegate.find_by(table_object_id: obj.id, name: "type")
				if type_prop
					type_prop.value = type
				else
					# Create the type property
					type_prop = PropertyDelegate.new(table_object_id: obj.id, name: "type", value: type)
				end
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(type_prop.save))

				# Check if the user has enough free storage
				size_prop = PropertyDelegate.find_by(table_object_id: obj.id, name: "size")
				old_file_size = 0
				if size_prop
					old_file_size = size_prop.value.to_i
				end

				file_size = get_file_size(request.body)
				free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage
				file_size_difference = file_size - old_file_size

				ValidationService.raise_validation_error(ValidationService.validate_storage_space(free_storage, file_size_difference))

				begin
					# Upload the new file
					blob = BlobOperationsService.upload_blob(app.id, obj.id, request.body)
					etag = blob.properties[:etag]
					etag = etag[1...etag.size-1]
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(false))
				end

				# Update the size and etag properties
				if !size_prop
					size_prop = PropertyDelegate.new(table_object_id: obj.id, name: "size", value: file_size)
				else
					size_prop.value = file_size
				end

				etag_prop = PropertyDelegate.find_by(table_object_id: obj.id, name: "etag")
		
				if !etag_prop
					etag_prop = PropertyDelegate.new(table_object_id: obj.id, name: "etag", value: etag)
				else
					etag_prop.value = etag
				end

				# Save the new used_storage value
				UtilsService.update_used_storage(user, app, file_size_difference)

				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(size_prop.save))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(etag_prop.save))

				# Update the etag
				obj.etag = generate_table_object_etag(obj)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				# Save that the user was active
				user.last_active = Time.now
				user.save

				users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
				if !users_app.nil?
					users_app.last_active = Time.now
					users_app.save
				end

				# Notify connected clients of the updated object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 1, session_id: session_id)

				# Return the data
				result = obj.attributes

				properties = Hash.new
				PropertyDelegate.where(table_object_id: obj.id).each do |prop|
					properties[prop.name] = prop.value
				end

				result["properties"] = properties
				result["etag"] = obj.etag
				render json: result, status: 200
			else
				# The object is not a file
				ValidationService.raise_validation_error(ValidationService.validate_content_type_json(type))

				# Update the properties of the object
				body = ValidationService.parse_json(request.body.string)

				# Validate name and value of each property
				body.each do |key, value|
					next if value == nil || value.to_s.length == 0

					ValidationService.raise_multiple_validation_errors([
						ValidationService.validate_property_name_too_short(key),
						ValidationService.validate_property_name_too_long(key),
						ValidationService.validate_property_value_too_short(value),
						ValidationService.validate_property_value_too_long(value)
					])
				end

				# Get all properties of the table object
				props = Array.new
				PropertyDelegate.where(table_object_id: obj.id).each { |prop| props.push(prop) }

				body.each do |name, value|
					prop = props.find { |p| p.name == name }

					if value == nil || value.to_s.length == 0
						# Delete the property, if there is one
						prop.destroy if prop
					elsif !prop
						# Create the property type
						create_property_type(table, name, value)

						# Create the property
						new_prop = PropertyDelegate.new(name: name, value: value.to_s, table_object_id: obj.id)
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
					else
						# Update the property
						prop.value = value.to_s
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
					end
				end

				# Reload the table object
				obj = TableObjectDelegate.find_by(id: obj.id)

				# Update the etag
				obj.etag = generate_table_object_etag(obj)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				# Save that the user was active
				user.last_active = Time.now
				user.save

				users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
				if !users_app.nil?
					users_app.last_active = Time.now
					users_app.save
				end

				# Notify connected clients of the updated object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 1, session_id: session_id)

				# Get the properties
				result = obj.attributes
				property_types = PropertyTypeDelegate.where(table_id: table.id)
				properties = Hash.new

				PropertyDelegate.where(table_object_id: obj.id).each do |prop|
					# Get the data type and convert the value
					properties[prop.name] = convert_value_to_data_type(prop.value, find_data_type(property_types, prop.name))
				end

				result["properties"] = properties
				result["etag"] = obj.etag

				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		object_id = params["id"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(object_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			
			if object_id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: object_id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: object_id.to_i)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = TableDelegate.find_by(id: obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))

			# Delete the file if it exists
			if obj.file
				BlobOperationsService.delete_blob(app.id, obj.id)
				size_prop = PropertyDelegate.find_by(table_object_id: obj.id, name: "size")

				if size_prop
					# Save the new used_storage value
					UtilsService.update_used_storage(user, app, -size_prop.value.to_i)
				end
			end

			# Save that the user was active
			user.last_active = Time.now
			user.save

			users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
			if !users_app.nil?
				users_app.last_active = Time.now
				users_app.save
			end

			# Notify connected clients of the deleted object
			TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 2, session_id: session_id)

			obj.destroy
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def add_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		id = params["id"]
		table_alias = params["table_alias"]

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

			if id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: id.to_i)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = TableDelegate.find_by(id: obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if table_alias
				table_alias = table_alias.to_i
				table2 = TableDelegate.find_by(id: table_alias)
				ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table2))

				app2 = AppDelegate.find_by(id: table2.app_id)
				ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app2))
				ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app2, dev))
			else
				table_alias = table.id
			end

			access = TableObjectUserAccessDelegate.new(table_object_id: obj.id, user_id: user.id, table_alias: table_alias)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(access.save))

			render json: access.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def remove_object
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		object_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			if object_id.include? '-'
				# The object id is a uuid
				obj = TableObjectDelegate.find_by(uuid: object_id)
			else
				# The object id is a id
				obj = TableObjectDelegate.find_by(id: object_id.to_i)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = TableDelegate.find_by(id: obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# Check if the user has access to the table object
			access = TableObjectUserAccessDelegate.find_by(user_id: user.id, table_object_id: obj.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object_user_access_does_not_exist(access))

			# Remove the TableObjectUserAccess
			access.destroy

			# Notify connected clients
			TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 2, session_id: session_id)

			# Save that the user was active
			user.last_active = Time.now
			user.save

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
   
	# Table methods
	def create_table
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["app_id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app))

			# Get the table name from the body
			body = ValidationService.parse_json(request.body.string)
			name = body["name"]

			ValidationService.raise_validation_error(ValidationService.validate_name_missing(name))

			table = TableDelegate.find_by(name: name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_already_exists(table))

			# Validate the name
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_for_table_too_short(name),
				ValidationService.validate_name_for_table_too_long(name),
				ValidationService.validate_name_contains_not_allowed_characters(name)
			])

			# Create the table and return the data
			table = TableDelegate.new(name: (name[0].upcase + name[1..-1]), app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))

			render json: table.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_table
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["app_id"]
      table_name = params["table_name"]
		
		default_count = 100
		default_page = 1

		count = params["count"].to_i || default_count
		page = params["page"].to_i || default_page

		count = count < 1 ? default_count : count
		page = page < 1 ? default_page : page

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_table_name_missing(table_name)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			table = TableDelegate.find_by(name: table_name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			# Save that the user was active
			user.last_active = Time.now
			user.save

			users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
			if !users_app.nil?
				users_app.last_active = Time.now
				users_app.save
			end

			# Return the data
			result = table.attributes
			array = Array.new

			if count > 0
				# Get all table objects of the user
				all_table_objects = Array.new
				TableObjectDelegate.where(user_id: user.id, table_id: table.id).each { |obj| all_table_objects.push(obj) }

				# Get the table objects the user has access to
				TableObjectUserAccessDelegate.where(user_id: user.id).each do |access|
					o = TableObjectDelegate.find_by(id: access.table_object_id)
					all_table_objects.push(o) if !o.nil? && access.table_alias == table.id
				end

				array_start = count * (page - 1)
				array_length = count > all_table_objects.count ? all_table_objects.count : count

				selected_table_objects = all_table_objects[array_start, array_length]

				if all_table_objects.count > 0
					pages = all_table_objects.count % count == 0 ? all_table_objects.count / count : (all_table_objects.count / count) + 1
				else
					pages = 1
				end
				
				if selected_table_objects
					selected_table_objects.each do |table_object|
						# Generate the etag if the table object has none
						if table_object.etag.nil?
							table_object.etag = generate_table_object_etag(table_object)
							table_object.save
						end

						object = Hash.new
						object["id"] = table_object.id
						object["table_id"] = table_object.table_id
						object["uuid"] = table_object.uuid
						object["etag"] = table_object.etag
						
						array.push(object)
					end
				end
			end
			
			result["pages"] = pages
			result["table_objects"] = array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_table_by_id
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		table_id = params["id"]
		
		default_count = 100
		default_page = 1

		count = params["count"].to_i || default_count
		page = params["page"].to_i || default_page

		count = count < 1 ? default_count : count
		page = page < 1 ? default_page : page

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(table_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = TableDelegate.find_by(id: table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			# Save that the user was active
			user.last_active = Time.now
			user.save

			users_app = UsersAppDelegate.find_by(app_id: app.id, user_id: user.id)
			if !users_app.nil?
				users_app.last_active = Time.now
				users_app.save
			end

			# Return the data
			result = table.attributes
			array = Array.new
			
			if count > 0
				# Get all table objects of the user
				all_table_objects = Array.new
				TableObjectDelegate.where(user_id: user.id, table_id: table.id).each { |obj| all_table_objects.push(obj) }

				# Get the table objects the user has access to
				TableObjectUserAccessDelegate.where(user_id: user.id).each do |access|
					o = TableObjectDelegate.find_by(id: access.table_object_id)
					all_table_objects.push(o) if !o.nil? && access.table_alias == table.id
				end

				array_start = count * (page - 1)
				array_length = count > all_table_objects.count ? all_table_objects.count : count

				selected_table_objects = all_table_objects[array_start, array_length]

				if all_table_objects.count > 0
					pages = all_table_objects.count % count == 0 ? all_table_objects.count / count : (all_table_objects.count / count) + 1
				else
					pages = 1
				end

				if selected_table_objects
					selected_table_objects.each do |table_object|
						# Generate the etag if the table object has none
						if table_object.etag.nil?
							table_object.etag = generate_table_object_etag(table_object)
							table_object.save
						end

						object = Hash.new
						object["id"] = table_object.id
						object["table_id"] = table_object.table_id
						object["uuid"] = table_object.uuid
						object["etag"] = table_object.etag
						
						array.push(object)
					end
				end
			end
			
			result["pages"] = pages
			result["table_objects"] = array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_table_by_id_and_auth
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		table_id = params["id"]
		user_id = params["user_id"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_auth_missing(auth),
				ValidationService.validate_id_missing(table_id)
			])

			api_key = auth.split(",")[0]
			sig = auth.split(",")[1]
			
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			
			dev = DevDelegate.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = TableDelegate.find_by(id: table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			# Check if the table belongs to an app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(AppDelegate.find_by(id: table.app_id), dev))

			# Return the data
			result = table.attributes
			array = Array.new

			# Get all table objects of the user
			all_table_objects = Array.new
			TableObjectDelegate.where(user_id: user_id, table_id: table.id).each { |obj| all_table_objects.push(obj) }

			# Get the table objects the user has access to
			TableObjectUserAccessDelegate.where(user_id: user_id).each do |access|
				o = TableObjectDelegate.find_by(id: access.table_object_id)
				all_table_objects.push(o) if !o.nil? && access.table_alias == table.id
			end

			all_table_objects.each do |obj|
				# Generate the etag if the table object has none
				if obj.etag.nil?
					obj.etag = generate_table_object_etag(obj)
					obj.save
				end

				object = Hash.new
				object["id"] = obj.id
				object["table_id"] = table_object.table_id
				object["uuid"] = obj.uuid
				object["etag"] = obj.etag

				array.push(object)
			end

			result["table_objects"] = array
			render json: result, status: 200
		rescue => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def update_table
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		table_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(table_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = TableDelegate.find_by(id: table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))
			
			object = ValidationService.parse_json(request.body.string)

			# Validate the properties
			name = object["name"]
			if name
				ValidationService.raise_multiple_validation_errors([
					ValidationService.validate_table_name_too_short(name),
					ValidationService.validate_table_name_too_long(name),
					ValidationService.validate_table_name_contains_not_allowed_characters(name)
				])
			end

			table.name = (name[0].upcase + name[1..-1])
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))

			result = table
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_table
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		table_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(table_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = TableDelegate.find_by(id: table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = AppDelegate.find_by(id: table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Delete the table
			table.destroy
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	# End table methods

	# Notification methods
	def create_notification
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]		# Optional
		app_id = params["app_id"]
		time = params["time"]		# The unix timestamp as integer
		interval = params["interval"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_time_missing(time)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			if !uuid || uuid.length < 1
				uuid = SecureRandom.uuid
			end

			# Check if the uuid is already in use
			ValidationService.raise_validation_error(ValidationService.validate_notification_uuid_taken(uuid))

			# Validate the properties
			body = ValidationService.parse_json(request.body.string)
			body.each do |key, value|
				if value && value.length > 0
					ValidationService.raise_multiple_validation_errors([
						ValidationService.validate_property_name_too_short(key),
						ValidationService.validate_property_name_too_long(key),
						ValidationService.validate_property_value_too_short(value),
						ValidationService.validate_property_value_too_long(value)
					])
				end
			end

			# Create the notification
			datetime = Time.at(time.to_i)
			notification = NotificationDelegate.new(uuid: uuid, app_id: app.id, user_id: user.id, time: datetime, interval: 0)

			if interval
				notification.interval = interval.to_i
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(notification.save))

			# Create the properties
			properties = Hash.new
			body.each do |key, value|
				if value && value.length > 0
					property = NotificationPropertyDelegate.new(notification_id: notification.id, name: key, value: value)
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(property.save))
					properties[key] = value
				end
			end

			# Return the data
			result = notification.attributes
			result["properties"] = properties

			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_notification
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]

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

			notification = NotificationDelegate.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(AppDelegate.find_by(id: notification.app_id), dev))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(UserDelegate.find_by(id: notification.user_id), user))

			# Return the notification
			result = notification.attributes

			# Return the time as int
			result["time"] = notification.time.to_i

			# Get the properties
			properties = Hash.new
			NotificationPropertyDelegate.where(notification_id: notification.id).each do |property|
				properties[property.name] = property.value
			end
			result["properties"] = properties

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_all_notifications
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["app_id"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_app_id_missing(app_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = AppDelegate.find_by(id: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# Return the notifications
			notifications = NotificationDelegate.where(user_id: user.id, app_id: app.id)
			notifications_array = Array.new

			notifications.each do |notification|
				hash = notification.attributes
				hash["time"] = notification.time.to_i

				# Get the properties
				properties = Hash.new
				NotificationPropertyDelegate.where(notification_id: notification.id).each do |property|
					properties[property.name] = property.value
				end
				hash["properties"] = properties

				notifications_array.push(hash)
			end

			result = Hash.new
			result["notifications"] = notifications_array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def update_notification
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]
		time = params["time"]
		interval = params["interval"]

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

			notification = NotificationDelegate.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(AppDelegate.find_by(id: notification.app_id), dev))

			# Validate the content type
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(UserDelegate.find_by(id: notification.user_id), user))

			# Validate the properties
			body = ValidationService.parse_json(request.body.string)
			body.each do |key, value|
				if value && value.length > 0
					ValidationService.raise_multiple_validation_errors([
						ValidationService.validate_property_name_too_short(key),
						ValidationService.validate_property_name_too_long(key),
						ValidationService.validate_property_value_too_short(value),
						ValidationService.validate_property_value_too_long(value)
					])
				end
			end

			# Save the new time and interval values
			if time
				notification.time = Time.at(time.to_i)
			end

			if interval
				notification.interval = interval.to_i
			end
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(notification.save))

			# Update the properties
			body.each do |key, value|
				prop = NotificationPropertyDelegate.find_by(name: key, notification_id: notification.id)

				if value
					if !prop && value.length > 0			# If the property does not exist and there is a value, create the property
						new_prop = NotificationPropertyDelegate.new(notification_id: notification.id, name: key, value: value)
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
					elsif prop && value.length == 0		# If there is a property and the length of the value is 0, delete the property
						prop.destroy
					elsif value.length > 0					# There is a new value for the property, update the property
						prop.value = value
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
					end
				end
			end

			# Return the data
			properties = Hash.new
			NotificationPropertyDelegate.where(notification_id: notification.id).each do |property|
				properties[property.name] = property.value
			end

			result = notification.attributes
			result["time"] = notification.time.to_i
			result["properties"] = properties

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_notification
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]

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

			notification = NotificationDelegate.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(AppDelegate.find_by(id: notification.app_id), dev))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(UserDelegate.find_by(id: notification.user_id), user))

			# Delete the notification
			notification.destroy
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	# End Notification methods

	# WebPushSubscription methods
   def create_subscription
      jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]	# Optional

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

			if !uuid || uuid.length < 1
				uuid = SecureRandom.uuid
			end

			# Check if the uuid is already in use
			ValidationService.raise_validation_error(ValidationService.validate_subscription_uuid_taken(uuid))

			# Check if the Content-Type is application/json
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

			# Validate the values
			body = ValidationService.parse_json(request.body.string)

			endpoint_key = "endpoint"
			p256dh_key = "p256dh"
			auth_key = "auth"

			endpoint = body[endpoint_key]
			p256dh = body[p256dh_key]
			auth = body[auth_key]

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_endpoint_missing(endpoint),
				ValidationService.validate_p256dh_missing(p256dh),
				ValidationService.validate_subscription_auth_missing(auth)
			])

			# Create the subscription
			subscription = WebPushSubscriptionDelegate.new(user_id: user.id, uuid: uuid, endpoint: endpoint, p256dh: p256dh, auth: auth)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(subscription.save))

			# Return the data
			result = subscription.attributes
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

   def get_subscription
      jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_uuid_missing(uuid)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			subscription = WebPushSubscriptionDelegate.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_does_not_exist(subscription))
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_belongs_to_user(subscription, user))

			# Return the subscription
			result = subscription.attributes
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_subscription
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		uuid = params["uuid"]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_uuid_missing(uuid)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = UserDelegate.find_by(id: user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = DevDelegate.find_by(id: dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			subscription = WebPushSubscriptionDelegate.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_does_not_exist(subscription))
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_belongs_to_user(subscription, user))

			# Delete the subscription
			subscription.destroy
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	# End WebPushSubscription methods
   
   private
   def generate_token
      SecureRandom.hex(20)
	end

	def find_data_type(property_types, name)
		property_type = property_types.find { |type| type.name == name }
		return property_type ? property_type.data_type : 0
	end

	def get_data_type_of_value(value)
		return 1 if value.is_a?(TrueClass) || value.is_a?(FalseClass)
		return 2 if value.is_a?(Integer)
		return 3 if value.is_a?(Float)
		return 0
	end
	
	def convert_value_to_data_type(value, data_type)
		# Try to convert the value from string to the specified type
		# Return the original value if the parsing throws an exception
		return value == "true" if data_type == 1
		return Integer value rescue value if data_type == 2
		return Float value rescue value if data_type == 3
		return value
	end

	def create_property_type(table, name, value)
		# Check if a PropertyType with the name already exists
		property_type = PropertyTypeDelegate.find_by(table_id: table.id, name: name)
		return if property_type

		# Get the data type of the property value
		data_type = get_data_type_of_value(value)

		# Create the property type
		property_type = PropertyTypeDelegate.new(table_id: table.id, name: name, data_type: data_type)
		ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(property_type.save))
	end
end