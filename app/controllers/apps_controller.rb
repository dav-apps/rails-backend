class AppsController < ApplicationController
	# App methods
	def create_app
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		name = params["name"]
      desc = params["desc"]
      link_web = params["link_web"]
      link_play = params["link_play"]
      link_windows = params["link_windows"]
		
      begin
         ValidationService.raise_multiple_validation_errors([
            ValidationService.validate_jwt_missing(jwt),
            ValidationService.validate_name_missing(name),
            ValidationService.validate_desc_missing(desc)
         ])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

         # Validate properties
         ValidationService.raise_multiple_validation_errors([
            ValidationService.validate_name_for_app_too_short(name),
            ValidationService.validate_name_for_app_too_long(name),
            ValidationService.validate_desc_too_short(desc),
            ValidationService.validate_desc_too_long(desc)
         ])

			# Validate the links
         validations = Array.new

			if link_web
            validations.push(ValidationService.validate_link_web_not_valid(link_web))
			end

			if link_play
            validations.push(ValidationService.validate_link_play_not_valid(link_play))
			end

			if link_windows
            validations.push(ValidationService.validate_link_windows_not_valid(link_windows))
         end
         
         ValidationService.raise_multiple_validation_errors(validations)

			# Create the app
			app = App.new(name: name, description: desc, dev_id: user.dev.id)

			# Save existing links
			if link_web
				app.link_web = link_web
			end

			if link_play
				app.link_play = link_play
			end

			if link_windows
				app.link_windows = link_windows
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(app.save))
			result = app
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_app
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website or from the associated dev
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app))

			# Return the data
			tables = Array.new
			app.tables.each do |table|
				tables.push(table)
			end
			
			events = Array.new
			app.events.each do |event|
				events.push(event)
			end
			
			result = app.attributes
			result["tables"] = tables
			result["events"] = events
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_active_users_of_app
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		app_id = params["id"]
		start_timestamp = params["start"] ? DateTime.strptime(params["start"],'%s').beginning_of_day : (Time.now - 1.month).beginning_of_day
		end_timestamp = params["end"] ? DateTime.strptime(params["end"],'%s').beginning_of_day : Time.now.beginning_of_day

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

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website and by the dev of the app
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			days = Array.new
			ActiveAppUser.where("app_id = ? AND time >= ? AND time <= ?", app.id, start_timestamp, end_timestamp).each do |active_user|
				day = Hash.new
				day["time"] = active_user.time.to_s
				day["count_daily"] = active_user.count_daily
				day["count_monthly"] = active_user.count_monthly
				day["count_yearly"] = active_user.count_yearly
				days.push(day)
			end

			result = Hash.new
			result["days"] = days
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_all_apps
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))

			api_key = auth.split(",")[0]
         sig = auth.split(",")[1]

			dev = Dev.find_by(api_key: api_key)
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			app.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
   
	# TableObject methods
   def create_object
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		table_name = params["table_name"]
		table_id = params["table_id"]
      app_id = params["app_id"]
		visibility = params["visibility"]
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if table_id
				table = Table.find_by(id: table_id)
			elsif table_name
				table = Table.find_by(name: table_name, app_id: app_id)

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
					table = Table.new(app_id: app.id, name: (table_name[0].upcase + table_name[1..-1]))
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

         type = request.headers["Content-Type"]
         ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(type))

			obj = TableObject.new(table_id: table.id, user_id: user.id)

			if uuid
				obj.uuid = uuid
			else
				obj.uuid = SecureRandom.uuid
			end

			begin
				if visibility && visibility.to_i <= 2 && visibility.to_i >= 0
					obj.visibility = visibility.to_i
				end
			end

			# If there is an ext property, save object as a file
			if !ext || ext.length < 1
				# Save the object normally
				# Content-Type must be application/json
				ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				object = ValidationService.parse_json(request.body.string)
				ValidationService.raise_validation_error(ValidationService.validate_object_missing(object))

				object.each do |key, value|
					if value
						if value.length > 0
							ValidationService.raise_multiple_validation_errors([
								ValidationService.validate_property_name_too_short(key),
								ValidationService.validate_property_name_too_long(key),
								ValidationService.validate_property_value_too_short(value),
								ValidationService.validate_property_value_too_long(value)
							])
						end
					end
				end

				properties = Hash.new
				
				object.each do |key, value|
					if value
						if value.length > 0
							property = Property.new(table_object_id: obj.id, name: key, value: value)
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(property.save))
							properties[key] = value
						end
					end
				end

				# Save that user uses the app
				users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
				if !users_app
					users_app = UsersApp.create(app_id: app.id, user_id: user.id)
					users_app.save
				end

				# Save that the user was active
				user.update_column(:last_active, Time.now)
				users_app.update_column(:last_active, Time.now)

				# Notify connected clients of the new object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 0, session_id: session_id)

				# Return the data
				result = obj.attributes
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)

				render json: result, status: 201
			else
				# Save the object as a file
				# Check if the user has enough free storage
				file_size = get_file_size(request.body)
				free_storage = get_total_storage(user.plan, user.confirmed) - user.used_storage
				obj.file = true

				ValidationService.raise_validation_error(ValidationService.validate_storage_space(free_storage, file_size))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))

				begin
					blob = BlobOperationsService.upload_blob(app.id, obj.id, request.body)
					etag = blob.properties[:etag]
					# Remove the first and the last character of etag, because they are "" for whatever 
					etag = etag[1...etag.size-1]

					# Save extension as property
					ext_prop = Property.new(table_object_id: obj.id, name: "ext", value: ext)
					# Save etag as property
					etag_prop = Property.new(table_object_id: obj.id, name: "etag", value: etag)
					# Save the new used_storage
					update_used_storage(user.id, app.id, file_size)

					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(ext_prop.save))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(etag_prop.save))
               
               # Create a property for the file size
					size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)
               ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(size_prop.save))
               
               # Create a property for the content type
               type_prop = Property.new(table_object_id: obj.id, name: "type", value: type)
               ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(type_prop.save))

					# Save that user uses the app
					users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
					if !users_app
						users_app = UsersApp.create(app_id: app.id, user_id: user.id)
						users_app.save
					end

					# Return the data
					result = obj.attributes

					properties = Hash.new
					obj.properties.each do |prop|
						properties[prop.name] = prop.value
					end

					# Save that the user was active
					user.update_column(:last_active, Time.now)
					users_app.update_column(:last_active, Time.now)

					# Notify connected clients of the new object
					TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 0, session_id: session_id)

					result["properties"] = properties
					result["etag"] = generate_table_object_etag(obj)
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		object_id = params["id"]
		token = params["access_token"]
		file = params["file"]
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_id_missing(object_id))

			obj = TableObject.find_by(uuid: object_id)
			if !obj
				obj = TableObject.find_by_id(object_id)
			end
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			can_access = false

			if obj.visibility != 2
				if !jwt || jwt.length < 1
					if !token || token.length < 1
						# JWT and token missing
						jwt_validation = ValidationService.validate_jwt_missing(jwt)
						token_validation = ValidationService.validate_access_token_missing(token)
						errors = [jwt_validation, token_validation]
						raise RuntimeError, errors.to_json
					else
						# Check if the token is valid
						obj.access_tokens.each do |access_token|
							if access_token.token == token
								can_access = true
							end
						end

						if !can_access
							ValidationService.raise_validation_error(ValidationService.get_access_not_allowed_error)
						end
					end
				else
					# There is a jwt
					jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
					ValidationService.raise_validation_error(jwt_signature_validation[0])
					user_id = jwt_signature_validation[1][0]["user_id"]
					dev_id = jwt_signature_validation[1][0]["dev_id"]

					user = User.find_by_id(user_id)
					ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

					dev = Dev.find_by_id(dev_id)
					ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

					ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

					if obj.visibility != 1
						ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))
					end

					# Save that the user was active
					user.update_column(:last_active, Time.now)

					users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
					users_app.update_column(:last_active, Time.now) if users_app
				end
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
					obj.properties.each do |prop|
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
				# Return the object data
				result = obj.attributes
				properties = Hash.new
				obj.properties.each do |prop|
					properties[prop.name] = prop.value
				end
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)

				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
   end
   
   def get_object_with_auth
      auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		id = params["id"]
		file = params["file"]

		begin
			# Validate the auth
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))

			api_key, sig = auth.split(',')

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			# Find the object
         obj = TableObject.find_by(uuid: id)
         if !obj
				obj = TableObject.find_by_id(id)
         end
         ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

         table = Table.find_by_id(obj.table_id)
         ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))
         
         app = App.find_by_id(table.app_id)
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
					obj.properties.each do |prop|
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
				# Return the data
				result = obj.attributes
				properties = Hash.new
				obj.properties.each do |prop|
					properties[prop.name] = prop.value
				end
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)

				render json: result, status: 200
			end
      rescue => e
         validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
      end
   end
	
	def update_object
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		object_id = params["id"]
		visibility = params["visibility"]
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			obj = TableObject.find_by(uuid: object_id)

			if !obj
				obj = TableObject.find_by_id(object_id)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))
			
			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			type = request.headers["Content-Type"]
			ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(type))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))

			# If there is a new visibility, save it
			begin
				if visibility && visibility.to_i <= 2 && visibility.to_i >= 0
					obj.visibility = visibility.to_i
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(obj.save))
				end
			end

			if obj.file
				if ext && ext.length > 0
					# Update the ext property
					ext_prop = Property.find_by(table_object_id: obj.id, name: "ext")
					ext_prop.value = ext
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(ext_prop.save))
				end

				# Update the type property
				type_prop = Property.find_by(table_object_id: obj.id, name: "type")
				if type_prop
					type_prop.value = type
				else
					# Create the type property
					type_prop = Property.new(table_object_id: obj.id, name: "type", value: type)
				end
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(type_prop.save))

				# Check if the user has enough free storage
				size_prop = Property.find_by(table_object_id: obj.id, name: "size")
				old_file_size = 0
				if size_prop
					old_file_size = size_prop.value.to_i
				end

				file_size = get_file_size(request.body)
				free_storage = get_total_storage(user.plan, user.confirmed) - user.used_storage
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
					size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)
				else
					size_prop.value = file_size
				end

				etag_prop = Property.find_by(table_object_id: obj.id, name: "etag")
		
				if !etag_prop
					etag_prop = Property.new(table_object_id: obj.id, name: "etag", value: etag)
				else
					etag_prop.value = etag
				end

				# Save the new used_storage value
				update_used_storage(user.id, app.id, file_size_difference)

				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(size_prop.save))
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(etag_prop.save))

				# Save that the user was active
				user.update_column(:last_active, Time.now)

				users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
				users_app.update_column(:last_active, Time.now) if users_app

				# Notify connected clients of the updated object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 1, session_id: session_id)

				# Return the data
				result = obj.attributes

				properties = Hash.new
				obj.properties.each do |prop|
					properties[prop.name] = prop.value
				end

				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)
				render json: result, status: 200
			else
				# The object is not a file
				ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

				# Update the properties of the object
				object = ValidationService.parse_json(request.body.string)

				object.each do |key, value|
					if value && value.length > 0
						ValidationService.raise_multiple_validation_errors([
							ValidationService.validate_property_name_too_short(key),
							ValidationService.validate_property_name_too_long(key),
							ValidationService.validate_property_value_too_short(value),
							ValidationService.validate_property_value_too_long(value)
						])
					end
				end

				object.each do |key, value|
					prop = Property.find_by(name: key, table_object_id: obj.id)

					if value
						if !prop && value.length > 0		# If the property does not exist and there is a value, create the property
							new_prop = Property.new(name: key, value: value, table_object_id: obj.id)
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
						elsif prop && value.length == 0		# If there is a property and the length of the value is 0, delete the property
							prop.destroy!
						elsif value.length > 0		# There is a new value for the property, update the property
							prop.value = value
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
						end
					end
				end

				# Save that the user was active
				user.update_column(:last_active, Time.now)

				users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
				users_app.update_column(:last_active, Time.now) if users_app

				# Notify connected clients of the updated object
				TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 1, session_id: session_id)

				# Get the properties
				properties = Hash.new
				obj.properties.each do |property|
					properties[property.name] = property.value
				end

				result = obj.attributes
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)
				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def delete_object
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			obj = TableObject.find_by(uuid: object_id)

			if !obj
				obj = TableObject.find_by_id(object_id)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(obj))

			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))

			# Delete the file if it exists
			if obj.file
				BlobOperationsService.delete_blob(app.id, obj.id)
				size_prop = obj.properties.find_by(name: "size")

				if size_prop
					# Save the new used_storage value
					update_used_storage(user.id, app.id, -size_prop.value.to_i)
				end
			end

			# Save that the user was active
			user.update_column(:last_active, Time.now)

			users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
			users_app.update_column(:last_active, Time.now) if users_app

			# Notify connected clients of the deleted object
			TableObjectUpdateChannel.broadcast_to("#{user.id},#{app.id}", uuid: obj.uuid, change: 2, session_id: session_id)

			obj.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
   
	# Table methods
	def create_table
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		app_id = params["app_id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

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
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app))

			# Get the table name from the body
			body = ValidationService.parse_json(request.body.string)
			name = body["name"]

			ValidationService.raise_validation_error(ValidationService.validate_name_missing(name))

			table = Table.find_by(name: name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_already_exists(table))

			# Validate the name
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_for_table_too_short(name),
				ValidationService.validate_name_for_table_too_long(name),
				ValidationService.validate_name_contains_not_allowed_characters(name)
			])

			# Create the table and return the data
			table = Table.new(name: (name[0].upcase + name[1..-1]), app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))

			render json: table.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_table
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			table = Table.find_by(name: table_name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			# Save that the user was active
			user.update_column(:last_active, Time.now)

			users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
			users_app.update_column(:last_active, Time.now) if users_app

			# Return the data
			result = table.attributes
			array = Array.new

			if count > 0
				all_table_objects = table.table_objects.where(user_id: user.id)
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
						object = Hash.new
						object["id"] = table_object.id
						object["uuid"] = table_object.uuid
						object["etag"] = generate_table_object_etag(table_object)
						
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			# Save that the user was active
			user.update_column(:last_active, Time.now)

			users_app = UsersApp.find_by(app_id: app.id, user_id: user.id)
			users_app.update_column(:last_active, Time.now) if users_app

			# Return the data
			result = table.attributes
			array = Array.new
			
			if count > 0
				all_table_objects = table.table_objects.where(user_id: user.id)
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
						object = Hash.new
						object["id"] = table_object.id
						object["uuid"] = table_object.uuid
						object["etag"] = generate_table_object_etag(table_object)
						
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
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
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
			
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			# Check if the table belongs to an app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(table.app, dev))

			# Return the data
			result = table.attributes
			array = Array.new

			table_objects = table.table_objects.where(user_id: user_id)

			table_objects.each do |obj|
				object = Hash.new
				object["id"] = obj.id
				object["uuid"] = obj.uuid
				object["etag"] = generate_table_object_etag(obj)

				properties = Hash.new
				obj.properties.each do |prop|
					properties[prop.name] = prop.value
				end

				object["properties"] = properties

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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
			
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Delete the table
			table.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	# End table methods

	# Access Token methods
	def create_access_token
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			object = TableObject.find_by_id(object_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(object))

			table = Table.find_by_id(object.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(object, user))

			access_token = AccessToken.new(token: generate_token)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(access_token.save))

			relation = TableObjectsAccessToken.new(table_object_id: object.id, access_token_id: access_token.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(relation.save))

			result = access_token.attributes
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_access_token
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			object = TableObject.find_by_id(object_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(object))

			table = Table.find_by_id(object.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(object, user))

			# Return the data
			access_token = object.access_tokens

			result = Hash.new
			result["access_token"] = access_token
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	
	def add_access_token_to_object
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		object_id = params["id"]
		token = params["token"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(object_id),
				ValidationService.validate_access_token_missing(token)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			object = TableObject.find_by_id(object_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(object))

			table = Table.find_by_id(object.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(object, user))

			access_token = AccessToken.find_by(token: token)
			ValidationService.raise_validation_error(ValidationService.validate_access_token_does_not_exist(access_token))

			# Add access token relationship to object
			relation = TableObjectsAccessToken.new(table_object_id: object.id, access_token_id: access_token.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(relation.save))

			# Return the data
			result = access_token.attributes
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def remove_access_token_from_object
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		object_id = params["id"]
		token = params["token"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(object_id),
				ValidationService.validate_access_token_missing(token)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			object = TableObject.find_by_id(object_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(object))

			table = Table.find_by_id(object.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_does_not_exist(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(object, user))

			access_token = AccessToken.find_by(token: token)
			ValidationService.raise_validation_error(ValidationService.validate_access_token_does_not_exist(access_token))

			# Find access token relationship with object
			relation = TableObjectsAccessToken.find_by(table_object_id: object.id, access_token_id: access_token.id)

			if relation
				relation.destroy!
			end

			# If the access token belongs to no objects, destroy it
			if access_token.table_objects.length == 0
				access_token.destroy!
			end

			result = access_token.attributes
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	# End Access Token methods

	# Notification methods
	def create_notification
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

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
			notification = Notification.new(uuid: uuid, app_id: app.id, user_id: user.id, time: datetime, interval: 0)

			if interval
				notification.interval = interval
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(notification.save))

			# Create the properties
			properties = Hash.new
			body.each do |key, value|
				if value && value.length > 0
					property = NotificationProperty.new(notification_id: notification.id, name: key, value: value)
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		uuid = params["uuid"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			notification = Notification.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(notification.app, dev))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(notification.user, user))

			# Return the notification
			result = notification.attributes

			# Return the time as int
			result["time"] = notification.time.to_i

			# Get the properties
			properties = Hash.new
			notification.notification_properties.each do |property|
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# Return the notifications
			notifications = Notification.where(user: user, app: app)
			notifications_array = Array.new

			notifications.each do |notification|
				hash = notification.attributes
				hash["time"] = notification.time.to_i

				# Get the properties
				properties = Hash.new
				notification.notification_properties.each do |property|
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		uuid = params["uuid"]
		time = params["time"]
		interval = params["interval"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			notification = Notification.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(notification.app, dev))

			# Validate the content type
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(notification.user, user))

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
				notification.interval = interval
			end
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(notification.save))

			# Update the properties
			body.each do |key, value|
				prop = NotificationProperty.find_by(name: key, notification_id: notification.id)

				if value
					if !prop && value.length > 0			# If the property does not exist and there is a value, create the property
						new_prop = NotificationProperty.new(notification_id: notification.id, name: key, value: value)
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
					elsif prop && value.length == 0		# If there is a property and the length of the value is 0, delete the property
						prop.destroy!
					elsif value.length > 0					# There is a new value for the property, update the property
						prop.value = value
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
					end
				end
			end

			# Return the data
			properties = Hash.new
			notification.notification_properties.each do |property|
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		uuid = params["uuid"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			notification = Notification.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_notification_does_not_exist(notification))

			# Validate notification belongs to the app of the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(notification.app, dev))

			# Validate notification belongs to the user
			ValidationService.raise_validation_error(ValidationService.validate_user_is_user(notification.user, user))

			# Delete the notification
			notification.destroy!
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
      jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		uuid = params["uuid"]	# Optional

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			if !uuid || uuid.length < 1
				uuid = SecureRandom.uuid
			end

			# Check if the uuid is already in use
			ValidationService.raise_validation_error(ValidationService.validate_subscription_uuid_taken(uuid))

			# Check if the Content-Type is application/json
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

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
			subscription = WebPushSubscription.new(user: user, uuid: uuid, endpoint: endpoint, p256dh: p256dh, auth: auth)
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
      jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			subscription = WebPushSubscription.find_by(uuid: uuid)
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
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
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

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			subscription = WebPushSubscription.find_by(uuid: uuid)
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_does_not_exist(subscription))
			ValidationService.raise_validation_error(ValidationService.validate_web_push_subscription_belongs_to_user(subscription, user))

			# Delete the subscription
			subscription.destroy!
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
end