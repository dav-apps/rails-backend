class AppsController < ApplicationController
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
	link_blank_string = "_"
   
	# App methods
	def create_app
		name = params["name"]
      desc = params["desc"]
      link_web = params["link_web"]
      link_play = params["link_play"]
      link_windows = params["link_windows"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			name_validation = ValidationService.validate_name(name)
			desc_validation = ValidationService.validate_desc(desc)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(name_validation) if !name_validation[:success]
			errors.push(desc_validation) if !desc_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Validate properties
			errors = Array.new
			name_too_short_validation = ValidationService.validate_name_too_short(name)
			name_too_long_validation = ValidationService.validate_name_too_long(name)
			desc_too_short_validation = ValidationService.validate_desc_too_short(desc)
			desc_too_long_validation = ValidationService.validate_desc_too_long(desc)

			errors.push(name_too_short_validation) if !name_too_short_validation[:success]
			errors.push(name_too_long_validation) if !name_too_long_validation[:success]
			errors.push(desc_too_short_validation) if !desc_too_short_validation[:success]
			errors.push(desc_too_long_validation) if !desc_too_long_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			# Validate the links
			errors = Array.new

			if link_web
				link_web_validation = ValidationService.validate_link_web(link_web)
				errors.push(link_web_validation) if !link_web_validation[:success]
			end

			if link_play
				link_play_validation = ValidationService.validate_link_play(link_play)
				errors.push(link_play_validation) if !link_play_validation[:success]
			end

			if link_windows
				link_windows_validation = ValidationService.validate_link_windows(link_windows)
				errors.push(link_windows_validation) if !link_windows_validation[:success]
			end

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

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
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_app
		app_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(app_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

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
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_all_apps
		auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth(auth))

			api_key = auth.split(",")[0]
         sig = auth.split(",")[1]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

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
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def update_app
		app_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(app_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			object = ValidationService.parse_json(request.body.string)
			errors = Array.new

			name = object["name"]
			if name
				name_too_short_validation = ValidationService.validate_name_too_short(name)
				name_too_long_validation = ValidationService.validate_name_too_long(name)

				errors.push(name_too_short_validation) if !name_too_short_validation[:success]
				errors.push(name_too_long_validation) if !name_too_long_validation[:success]

				app.name = name
			end

			desc = object["description"]
			if desc
				desc_too_short_validation = ValidationService.validate_desc_too_short(desc)
				desc_too_long_validation = ValidationService.validate_desc_too_long(desc)
				
				errors.push(desc_too_short_validation) if !desc_too_short_validation[:success]
				errors.push(desc_too_long_validation) if !desc_too_long_validation[:success]

				app.description = desc
			end

			link_web = object["link_web"]
			if link_web
				link_web_validation = ValidationService.validate_link_web(link_web)
				errors.push(link_web_validation) if !link_web_validation[:success]

				app.link_web = link_web
			end

			link_play = object["link_play"]
			if link_play
				link_play_validation = ValidationService.validate_link_play(link_play)
				errors.push(link_play_validation) if !link_play_validation[:success]

				app.link_play = link_play
			end

			link_windows = object["link_windows"]
			if link_windows
				link_windows_validation = ValidationService.validate_link_windows(link_windows)
				errors.push(link_windows_validation) if !link_windows_validation[:success]

				app.link_windows = link_windows
			end

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			# Update the app
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(app.save))
			result = app
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def delete_app
		app_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(app_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			app.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end
   
	# TableObject methods
	def create_object
		table_name = params["table_name"]
		table_id = params["table_id"]
      app_id = params["app_id"]
		visibility = params["visibility"]
		ext = params["ext"]
		uuid = params["uuid"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			app_id_validation = ValidationService.validate_app_id(app_id)
			table_name_validation = ValidationService.validate_table_name_and_table_id(table_name, table_id)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(app_id_validation) if !app_id_validation[:success]
			errors.push(table_name_validation) if !table_name_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if table_id
				table = Table.find_by(id: table_id, app_id: app_id)
			else
				table = Table.find_by(name: table_name, app_id: app_id)

				if !table
					# If the dev is not logged in, return 2804: Resource does not exist: Table
					ValidationService.raise_validation_error(ValidationService.validate_users_dev_is_dev(user, dev, 2804))

					# Validate the table name
					table_name_too_short_validation = ValidationService.validate_table_name_too_short(table_name)
					table_name_too_long_validation = ValidationService.validate_table_name_too_long(table_name)
					table_name_invalid_validation = ValidationService.validate_table_name_invalid(table_name)
					errors = Array.new

					errors.push(table_name_too_short_validation) if !table_name_too_short_validation[:success]
					errors.push(table_name_too_long_validation) if !table_name_too_long_validation[:success]
					errors.push(table_name_invalid_validation) if !table_name_invalid_validation[:success]

					if errors.length > 0
						raise RuntimeError, errors.to_json
					end

					# Create the table
					table = Table.new(app_id: app.id, name: (table_name[0].upcase + table_name[1..-1]))
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))
				end
			end

			if uuid
				# Check if the uuid is already in use
				ValidationService.raise_validation_error(ValidationService.validate_table_object_uuid_taken(uuid))
			end

			ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(request.headers["Content-Type"]))

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
							property_name_too_short_validation = ValidationService.validate_property_name_too_short(key)
							property_name_too_long_validation = ValidationService.validate_property_name_too_long(key)
							property_value_too_short_validation = ValidationService.validate_property_value_too_short(value)
							property_value_too_long_validation = ValidationService.validate_property_value_too_long(value)
							errors = Array.new
							
							errors.push(property_name_too_short_validation) if !property_name_too_short_validation[:success]
							errors.push(property_name_too_long_validation) if !property_name_too_long_validation[:success]
							errors.push(property_value_too_short_validation) if !property_value_too_short_validation[:success]
							errors.push(property_value_too_long_validation) if !property_value_too_long_validation[:success]

							if errors.length > 0
								raise RuntimeError, errors.to_json
							end
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
				if !user.apps.find_by_id(app.id)
					users_app = UsersApp.create(app_id: app.id, user_id: user.id)
					users_app.save
				end

				# Return the data
				result = obj.attributes
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)
				render json: result, status: 201
			else
				# Save the object as a file
				# Check if the user has enough free storage
				file_size = get_file_size(request.body)
				free_storage = get_total_storage(user.plan) - user.used_storage
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
					
					size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(size_prop.save))

					# Save that user uses the app
					if !user.apps.find_by_id(app.id)
						users_app = UsersApp.create(app_id: app.id, user_id: user.id)
						users_app.save
					end

					# Return the data
					result = obj.attributes

					properties = Hash.new
					obj.properties.each do |prop|
						properties[prop.name] = prop.value
					end

					result["properties"] = properties
					result["etag"] = generate_table_object_etag(obj)
					render json: result, status: 201
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(false))
				end
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_object
		object_id = params["id"]
		token = params["access_token"]
		file = params["file"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			ValidationService.raise_validation_error(ValidationService.validate_id(object_id))

			obj = TableObject.find_by(uuid: object_id)
			if !obj
				obj = TableObject.find_by_id(object_id)
			end
			ValidationService.raise_validation_error(ValidationService.validate_table_object(obj))

			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))
			can_access = false

			if obj.visibility != 2
				if !jwt || jwt.length < 1
					if !token || token.length < 1
						# JWT and token missing
						jwt_validation = ValidationService.validate_jwt(jwt)
						token_validation = ValidationService.validate_access_token(token)
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
					jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
					ValidationService.raise_validation_error(jwt_signature_validation[0])
					user_id = jwt_signature_validation[1][0]["user_id"]
					dev_id = jwt_signature_validation[1][0]["dev_id"]

					user = User.find_by_id(user_id)
					ValidationService.raise_validation_error(ValidationService.validate_user(user))

					dev = Dev.find_by_id(dev_id)
					ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

					ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

					if obj.visibility != 1
						ValidationService.raise_validation_error(ValidationService.validate_table_object_belongs_to_user(obj, user))
					end
				end
			end

			if file == "true" && obj.file
				# Return the file of the object
				Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
				Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
				filename = "#{app.id}/#{obj.id}"

				begin
					client = Azure::Blob::BlobService.new
					blob = client.get_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename)

					result = blob[1]

					# Get the file extension
					obj.properties.each do |prop|
						if prop.name == "ext"
							filename += ".#{prop.value}"
						end
					end
				rescue Exception => e
					ValidationService.raise_validation_error(ValidationService.get_file_does_not_exist_error)
				end

				send_data(result, status: 200, filename: filename)
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
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end
	
	def update_object
		object_id = params["id"]
		visibility = params["visibility"]
		ext = params["ext"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(object_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			obj = TableObject.find_by(uuid: object_id)

			if !obj
				obj = TableObject.find_by_id(object_id)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object(obj))
			
			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_content_type_is_supported(request.headers["Content-Type"]))
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
					ext_prop = Property.find_by(name: "ext", table_object_id: obj.id)
					ext_prop.value = ext
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(ext_prop.save))
				end

				# Check if the user has enough free storage
				size_prop = Property.find_by(table_object_id: obj.id, name: "size")
				old_file_size = 0
				if size_prop
					old_file_size = size_prop.value.to_i
				end

				file_size = get_file_size(request.body)
				free_storage = get_total_storage(user.plan) - user.used_storage
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
					if value
						if value.length > 0
							name_too_short_validation = ValidationService.validate_property_name_too_short(key)
							name_too_long_validation = ValidationService.validate_property_name_too_long(key)
							value_too_short_validation = ValidationService.validate_property_value_too_short(value)
							value_too_long_validation = ValidationService.validate_property_value_too_long(value)
							errors = Array.new

							errors.push(name_too_short_validation) if !name_too_short_validation[:success]
							errors.push(name_too_long_validation) if !name_too_long_validation[:success]
							errors.push(value_too_short_validation) if !value_too_short_validation[:success]
							errors.push(value_too_long_validation) if !value_too_long_validation[:success]

							if errors.length > 0
								raise RuntimeError, errors.to_json
							end
						end
					end
				end

				properties = Hash.new
				object.each do |key, value|
					prop = Property.find_by(name: key, table_object_id: obj.id)

					if value
						if !prop && value.length > 0		# If the property does not exist and there is a value, create the property
							new_prop = Property.new(name: key, value: value, table_object_id: obj.id)
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
							properties[key] = value
						elsif prop && value.length == 0		# If there is a property and the length of the value is 0, delete the property
							prop.destroy!
						elsif value.length > 0		# There is a new value for the property
							prop.value = value
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
							properties[key] = value
						end
					end
				end

				result = obj.attributes
				result["properties"] = properties
				result["etag"] = generate_table_object_etag(obj)
				render json: result, status: 200
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def delete_object
		object_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(object_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			obj = TableObject.find_by(uuid: object_id)

			if !obj
				obj = TableObject.find_by_id(object_id)
			end

			ValidationService.raise_validation_error(ValidationService.validate_table_object(obj))

			table = Table.find_by_id(obj.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

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

			obj.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end
   
	# Table methods
	def create_table
		table_name = params["table_name"]
      app_id = params["app_id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			app_id_validation = ValidationService.validate_app_id(app_id)
			table_name_validation = ValidationService.validate_table_name(table_name)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(app_id_validation) if !app_id_validation[:success]
			errors.push(table_name_validation) if !table_name_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_user_is_dev(user, dev, app))

			table = Table.find_by(name: table_name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table_exists(table))

			# Validate the properties
			name_too_short_validation = ValidationService.validate_table_name_too_short(table_name)
			name_too_long_validation = ValidationService.validate_table_name_too_long(table_name)
			name_invalid_validation = ValidationService.validate_table_name_invalid(table_name)
			errors = Array.new

			errors.push(name_too_short_validation) if !name_too_short_validation[:success]
			errors.push(name_too_long_validation) if !name_too_long_validation[:success]
			errors.push(name_invalid_validation) if !name_invalid_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			# Create the table and return the data
			table = Table.new(name: (table_name[0].upcase + table_name[1..-1]), app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))
			result = table
			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end

	def get_table
		app_id = params["app_id"]
      table_name = params["table_name"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			app_id_validation = ValidationService.validate_app_id(app_id)
			table_name_validation = ValidationService.validate_table_name(table_name)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(app_id_validation) if !app_id_validation[:success]
			errors.push(table_name_validation) if !table_name_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			table = Table.find_by(name: table_name, app_id: app.id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			# Return the data
			result = table.attributes
			array = Array.new
         
			table.table_objects.each do |table_object|
				if table_object.user_id == user.id
					object = Hash.new
					object["id"] = table_object.id
					object["uuid"] = table_object.uuid
					object["etag"] = generate_table_object_etag(table_object)
					
					array.push(object)
				end
			end
			
			result["table_objects"] = array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end

	def get_table_by_id
		table_id = params["id"]      
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(table_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev_or_app_dev_is_dev(user, dev, app))

			result = table.attributes
			array = Array.new
			
			table.table_objects.each do |table_object|
				if table_object.user_id == user.id
					object = Hash.new
					object["id"] = table_object.id
					object["uuid"] = table_object.uuid
					object["etag"] = generate_table_object_etag(table_object)
					
					array.push(object)
				end
			end
			
			result["table_objects"] = array
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end

	def update_table
		table_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(table_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
			
			object = ValidationService.parse_json(request.body.string)

			# Validate the properties
			name = object["name"]
			if name
				name_too_short_validation = ValidationService.validate_name_too_short(name)
				name_too_long_validation = ValidationService.validate_name_too_long(name)
				name_invalid_validation = ValidationService.validate_table_name_invalid(name)
				errors = Array.new

				errors.push(name_too_short_validation) if !name_too_short_validation[:success]
				errors.push(name_too_long_validation) if !name_too_long_validation[:success]
				errors.push(name_invalid_validation) if !name_invalid_validation[:success]

				if errors.length > 0
					raise RuntimeError, errors.to_json
				end
			end

			table.name = (name[0].upcase + name[1..-1])
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(table.save))

			result = table
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end

	def delete_table
		table_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(table_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			table = Table.find_by_id(table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app.id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Delete the table
			table.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end

	def create_access_token
		object_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt(jwt)
			id_validation = ValidationService.validate_id(object_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev(dev))

			object = TableObject.find_by_id(object_id)
			ValidationService.raise_validation_error(ValidationService.validate_table_object(object))

			table = Table.find_by_id(object.table_id)
			ValidationService.raise_validation_error(ValidationService.validate_table(table))

			app = App.find_by_id(table.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app(app))

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
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)
			
			render json: result, status: validations.last["status"]
		end
	end
   
	def get_access_token
		object_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
                  else
                     table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
                     else
                        app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
                        else
                           if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
                           else
                              if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = object.access_tokens

											@result["access_token"] = access_token
											ok = true
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
	
	def add_access_token_to_object
		object_id = params["id"]
		token = params["token"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
		end
		
		if !token || token.length < 1
			errors.push(Array.new([2117, "Missing field: access_token"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						# Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
						else
							table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
							else
								app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
								else
									if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
									else
										if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = AccessToken.find_by(token: token)

											if !access_token
												errors.push(Array.new([2809, "Resource does not exist: AccessToken"]))
                           			status = 400
											else
												# Add access token relationship to object
												relation = TableObjectsAccessToken.new(table_object_id: object.id, access_token_id: access_token.id)

												if !relation.save
													errors.push(Array.new([1103, "Unknown validation error"]))
													status = 500
												else
													@result = access_token.attributes
													ok = true
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
		end

		if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
	end

	def remove_access_token_from_object
		object_id = params["id"]
		token = params["token"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
		end
		
		if !token || token.length < 1
			errors.push(Array.new([2117, "Missing field: access_token"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						# Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
						else
							table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
							else
								app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
								else
									if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
									else
										if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = AccessToken.find_by(token: token)

											if !access_token
												errors.push(Array.new([2809, "Resource does not exist: AccessToken"]))
                           			status = 400
											else
												# Find access token relationship with object
												relation = TableObjectsAccessToken.find_by(table_object_id: object.id, access_token_id: access_token.id)

												if relation
													relation.destroy!
												end

												# If the access token belongs to no objects, destroy it
												if access_token.table_objects.length == 0
													access_token.destroy!
												end

												@result = access_token.attributes
												ok = true
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
   
   
   private
   def generate_token
      SecureRandom.hex(20)
   end
end