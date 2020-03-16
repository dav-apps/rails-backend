class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		path = params[:path]

		begin
			# Get the api
			@api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(@api))

			# Find the correct api endpoint
			api_endpoint = @api.api_endpoints.find_by(method: request.method, path: path)
			@vars = Hash.new
			@functions = Hash.new
			@errors = Array.new

			# Add the url params to the vars
			request.query_parameters.each do |key, value|
				@vars[key.to_s] = value
			end

			# Get the environment variables
			@vars["env"] = Hash.new
			@api.api_env_vars.each do |env_var|
				@vars["env"][env_var.name] = convert_env_value(env_var.class_name, env_var.value)
			end

			if !api_endpoint
				@api.api_endpoints.where(method: request.method).each do |endpoint|
					path_parts = endpoint.path.split('/')
					url_parts = path.split('/')
					next if path_parts.count != url_parts.count

					vars = Hash.new
					cancelled = false
					i = -1

					path_parts.each do |part|
						i += 1
						
						if url_parts[i] == part
							next
						elsif part[0] == ':'
							vars[part[1..part.size]] = url_parts[i]
							next
						end

						cancelled = true
						break
					end

					if !cancelled
						api_endpoint = endpoint
						vars.each do |key, value|
							@vars[key] = value
						end
						break
					end
				end
			end

			ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_does_not_exist(api_endpoint))

			# Parse the endpoint commands
			@parser = Sexpistol.new
			@parser.ruby_keyword_literals = true
			ast = @parser.parse_string(api_endpoint.commands)

			# Stop the execution of the program if this is true
			@execution_stopped = false

			ast.each do |element|
				break if @execution_stopped
				execute_command(element, @vars)
			end

		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	private
	def execute_command(command, vars)
		return nil if @execution_stopped
		return nil if @errors.count > 0

		if command.class == Array
			# Command is a function call
			if command[0].class == Array && (!command[1] || command[1].class == Array)
				# Command contains commands
				result = nil
				command.each do |c|
					result = execute_command(c, vars)
				end
				return result
			elsif command[0] == :var
				if command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop
					current_var = vars
					table_object = nil

					parts.each do |part|
						if current_var.is_a?(Hash)
							current_var = current_var[part]
						elsif current_var.is_a?(TableObject) && part == "properties"
							table_object = current_var
							current_var = current_var.properties
						else
							return nil
						end
					end

					if current_var.is_a?(Hash)
						current_var[last_part] = execute_command(command[2], vars)
					elsif current_var.class.to_s == "Property::ActiveRecord_Associations_CollectionProxy"
						props = current_var.where(name: last_part)
						
						if props.count == 0 && table_object
							# Create a new property
							prop = Property.new(table_object_id: table_object.id, name: last_part, value: execute_command(command[2], vars))
							prop.save
							return prop.value
						else
							# Update the value of the property
							prop = props[0]
							prop.value = execute_command(command[2], vars)
							prop.save
							return prop.value
						end
					end
				else
					vars[command[1].to_s] = execute_command(command[2], vars)
				end
			elsif command[0] == :return
				return execute_command(command[1], vars)
			elsif command[0] == :hash
				hash = Hash.new

				i = 1
				while command[i]
					hash[command[i][0].to_s] = execute_command(command[i][1], vars)
					i += 1
				end
				
				return hash
			elsif command[0] == :list
				list = Array.new

				i = 1
				while command[i]
					result = execute_command(command[i], vars)
					list.push(result) if result != nil
					i += 1
				end

				return list
			elsif command[0] == :if
				if execute_command(command[1], vars)
					return execute_command(command[2], vars)
				else
					i = 3
					while command[i] != nil
						if command[i] == :elseif && execute_command(command[i + 1], vars)
							return execute_command(command[i + 2], vars)
						elsif command[i] == :else
							return execute_command(command[i + 1], vars)
						end
						i += 3
					end
				end
			elsif command[0] == :for && command[2] == :in
				array = execute_command(command[3], vars)
				return nil if array.class != Array
				var_name = command[1]
				commands = command[4]

				array.each do |entry|
					vars[var_name.to_s] = entry
					execute_command(commands, vars)
				end
			elsif command[0] == :def
				# Function definition
				name = command[1].to_s
				function = Hash.new

				# Get the function parameters
				parameters = Array.new
				command[2].each do |parameter|
					parameters.push(parameter.to_s)
				end

				function["parameters"] = parameters
				function["commands"] = command[3]
				@functions[name] = function
				return nil
			elsif command[0] == :func
				# Function call
				name = command[1]
				function = @functions[name.to_s]

				if function
					# Clone the vars for the function call
					args = Marshal.load(Marshal.dump(vars))

					i = 0
					function["parameters"].each do |param|
						args[param] = execute_command(command[2][i], vars)
						i += 1
					end

					return execute_command(function["commands"], args)
				else
					# Try to get the function from the database
					function = ApiFunction.find_by(api: @api, name: name)
					
					if function
						# Clone the vars for the function call
						args = Marshal.load(Marshal.dump(vars))
						params = Array.new

						i = 0
						function.params.split(',').each do |param|
							args[param] = execute_command(command[2][i], vars)
							params.push(param)
							i += 1
						end

						ast_parent = Array.new
						ast = @parser.parse_string(function.commands)
						result = nil
						
						ast.each do |element|
							ast_parent.push(element)
						end

						# Save the function in the functions variable for later use
						func = Hash.new
						func["commands"] = ast_parent
						func["parameters"] = params
						@functions[function.name] = func

						return execute_command(ast_parent, args)
					end
				end
			elsif command[0] == :catch
				# Execute the commands in the first argument
				result = execute_command(command[1], vars)

				if @errors.length > 0
					# Add the errors to the variables and execute the commands in the second argument
					vars["errors"] = Array.new

					while @errors.length > 0
						vars["errors"].push(@errors.pop)
					end

					result = execute_command(command[2], vars)
				end

				return result
			elsif command[0] == :throw_errors
				# Add the errors to the errors array
				i = 1
				while command[i] != nil
					@errors.push(execute_command(command[i], vars))
					i += 1
				end
				return @errors
			elsif command[0] == :decode_jwt
				jwt_parts = execute_command(command[1], vars).to_s.split('.')
				jwt = jwt_parts[0..2].join('.')
				session_id = jwt_parts[3].to_i
				
				secret = ENV["JWT_SECRET"]

				error = Hash.new
				error["name"] = "decode_jwt"
				
				if session_id != 0
					session = Session.find_by_id(session_id)

					if !session
						# Session does not exist
						error["code"] = 0
						@errors.push(error)
						return @errors
					elsif session.app_id != @api.app_id
						# Action not allowed
						error["code"] = 1
						@errors.push(error)
						return @errors
					end

					secret = session.secret
				end
				
				begin
					JWT.decode(jwt, secret, true, {algorithm: ENV['JWT_ALGORITHM']})[0]
				rescue JWT::ExpiredSignature
					# JWT expired
					error["code"] = 2
					@errors.push(error)
					return @errors
				rescue JWT::DecodeError
					# JWT decode failed
					error["code"] = 3
					@errors.push(error)
					return @errors
				rescue Exception
					# Generic error
					error["code"] = 4
					@errors.push(error)
					return @errors
				end
			elsif command[0] == :log
				result = execute_command(command[1], vars)
				puts result
				return result
			elsif command[0] == :to_int
				return execute_command(command[1], vars).to_i
			elsif command[0] == :is_nil
				return execute_command(command[1], vars) == nil
			elsif command[0].to_s == "#"
				# It's a comment. Ignore this command
				return nil
			elsif command[0] == :parse_json
				json = execute_command(command[1], vars)
				return nil if json.size < 2
				JSON.parse(json)
			elsif command[0] == :get_header
				return request.headers[command[1].to_s]
			elsif command[0] == :get_param
				return params[command[1]]
			elsif command[0] == :get_body
				if request.body.class == StringIO
					return request.body.string
				elsif request.body.class == Tempfile
					return request.body.read
				else
					return request.body
				end
			elsif command[0] == :get_error
				error = ApiError.find_by(api: @api, code: command[1])

				if error
					result = Hash.new
					result["code"] = error.code
					result["message"] = error.message
					return result
				end
			elsif command[0] == :render_json
				render json: execute_command(command[1], vars), status: execute_command(command[2], vars)
				break_execution
			elsif command[0] == :render_file
				result = execute_command(command[1], vars)
				type = execute_command(command[2], vars)
				filename = execute_command(command[3], vars)
				status = execute_command(command[4], vars)

				response.headers['Content-Length'] = result.size.to_s if result
				send_data(result, type: type, filename: filename, status: status)
				break_execution

			elsif command[0].to_s == "User.get"		# (id)
				User.find_by_id(execute_command(command[1], vars).to_i)
			elsif command[0].to_s == "Table.get"	# (id)
				table = Table.find_by(id: execute_command(command[1], vars).to_i)

				if table && table.app != @api.app
					# Action not allowed error
					error = Hash.new
					error["code"] = 1
					@errors.push(error)
					return @errors
				else
					return table
				end
			elsif command[0].to_s == "Table.get_table_objects"		# id, user_id
				table = Table.find_by(id: execute_command(command[1], vars).to_i)
				return nil if !table

				if table.app != @api.app
					# Action not allowed error
					error = Hash.new
					error["code"] = 1
					@errors.push(error)
					return @errors
				else
					return table.table_objects.where(user_id: execute_command(command[2], vars).to_i).to_a
				end
			elsif command[0].to_s == "TableObject.create"	# user_id, table_id, properties, visibility?
				# Get the table
				table = Table.find_by_id(execute_command(command[2], vars))
				error = Hash.new
				
				# Check if the table exists
				if !table
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Check if the table belongs to the same app as the api
				if table.app != @api.app
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Check if the user exists
				user = User.find_by_id(execute_command(command[1], vars))
				if !user
					error["code"] = 2
					@errors.push(error)
					return @errors
				end

				# Create the table object
				obj = TableObject.new
				obj.user = user
				obj.table = table
				obj.visibility = execute_command(command[4].to_i, vars) if command[4]
				obj.uuid = SecureRandom.uuid

				if !obj.save
					# Unexpected error
					error["code"] = 3
					@errors.push(error)
					return @errors
				end

				# Create the properties
				properties = execute_command(command[3], vars)
				properties.each do |key, value|
					prop = Property.new
					prop.table_object_id = obj.id
					prop.name = key
					prop.value = value
					prop.save
				end

				# Return the table object
				return obj
			elsif command[0].to_s == "TableObject.create_file"	# user_id, table_id, ext, type, file
				# Get the table
				table = Table.find_by_id(execute_command(command[2], vars))
				error = Hash.new

				# Check if the table exists
				if !table
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Check if the table belongs to the same app as the api
				if table.app != @api.app
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Check if the user exists
				user = User.find_by_id(execute_command(command[1], vars))
				if !user
					error["code"] = 2
					@errors.push(error)
					return @errors
				end

				# Create the table object
				obj = TableObject.new
				obj.user = user
				obj.table = table
				obj.uuid = SecureRandom.uuid
				obj.file = true

				ext = execute_command(command[3], vars)
				type = execute_command(command[4], vars)
				file = execute_command(command[5], vars)
				file_size = file.size

				# Check if the user has enough free storage
				free_storage = get_total_storage(user.plan, user.confirmed) - user.used_storage

				if free_storage < file_size
					error["code"] = 3
					@errors.push(error)
					return @errors
				end

				# Save the table object
				if !obj.save
					# Unexpected error
					error["code"] = 4
					@errors.push(error)
					return @errors
				end

				begin
					# Upload the file
					blob = BlobOperationsService.upload_blob(table.app_id, obj.id, StringIO.new(file))
					etag = blob.properties[:etag]

					# Remove the first and the last character of etag, because they are "" for whatever reason
					etag = etag[1...etag.size-1]
				rescue Exception => e
					error["code"] = 5
					@errors.push(error)
					return @errors
				end

				# Save extension as property
				ext_prop = Property.new(table_object_id: obj.id, name: "ext", value: ext)

				# Save etag as property
				etag_prop = Property.new(table_object_id: obj.id, name: "etag", value: etag)

				# Save the file size as property
				size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)

				# Save the content type as property
				type_prop = Property.new(table_object_id: obj.id, name: "type", value: type)

				# Update the used storage
				update_used_storage(user.id, table.app_id, file_size)

				# Save that user uses the app
				users_app = UsersApp.find_by(app_id: table.app_id, user_id: user.id)
				if !users_app
					users_app = UsersApp.create(app_id: table.app_id, user_id: user.id)
					users_app.save
				end

				# Create the properties
				if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
					error["code"] = 6
					@errors.push(error)
					return @errors
				end

				return obj
			elsif command[0].to_s == "TableObject.get"	# uuid
				obj = TableObject.find_by(uuid: execute_command(command[1], vars))
				return nil if !obj

				# Check if the table of the table object belongs to the same app as the api
				if obj.table.app != @api.app
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				return obj
			elsif command[0].to_s == "TableObject.get_file"	# uuid
				obj = TableObject.find_by(uuid: execute_command(command[1], vars))
				return nil if !obj.file

				# Check if the table of the table object belongs to the same app as the api
				if obj.table.app != @api.app
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
				Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
				filename = "#{obj.table.app.id}/#{obj.id}"

				# Download the file
				begin
					client = Azure::Blob::BlobService.new
					return client.get_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename)[1]
				rescue Exception => e
					return nil
				end
			elsif command[0].to_s == "TableObject.update"	# uuid, properties
				# Get the table object
				obj = TableObject.find_by(uuid: execute_command(command[1], vars))
				error = Hash.new

				# Check if the table object exists
				if !obj
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Make sure the object is not a file
				if obj.file
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Check if the table of the table object belongs to the same app as the api
				if obj.table.app != @api.app
					error["code"] = 2
					@errors.push(error)
					return @errors
				end

				# Update the properties of the table object
				properties = execute_command(command[2], vars)
				properties.each do |key, value|
					next if !value
					prop = Property.find_by(table_object_id: obj.id, name: key)

					if value.length > 0
						if !prop
							# Create the property
							new_prop = Property.new(name: key, value: value, table_object_id: obj.id)
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(new_prop.save))
						else
							# Update the property
							prop.value = value
							ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(prop.save))
						end
					elsif prop
						# Delete the property
						prop.destroy!
					end
				end
			elsif command[0].to_s == "TableObject.update_file"	# uuid, ext, type, file
				# Get the table object
				obj = TableObject.find_by(uuid: execute_command(command[1], vars))
				error = Hash.new

				# Check if the table object exists
				if !obj
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Check if the table object is a file
				if !obj.file
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Check if the table of the table object belongs to the same app as the api
				if obj.table.app != @api.app
					error["code"] = 2
					@errors.push(error)
					return @errors
				end

				# Get the properties
				ext_prop = Property.find_by(table_object_id: obj.id, name: "ext")
				etag_prop = Property.find_by(table_object_id: obj.id, name: "etag")
				size_prop = Property.find_by(table_object_id: obj.id, name: "size")
				type_prop = Property.find_by(table_object_id: obj.id, name: "type")

				ext = execute_command(command[2], vars)
				type = execute_command(command[3], vars)
				file = execute_command(command[4], vars)
				user = obj.user

				file_size = file.size
				old_file_size = size_prop ? size_prop.value.to_i : 0
				file_size_diff = file_size - old_file_size
				free_storage = get_total_storage(user.plan, user.confirmed) - user.used_storage

				# Check if the user has enough free storage
				if free_storage < file_size_diff
					error["code"] = 3
					@errors.push(error)
					return @errors
				end

				begin
					# Upload the new file
					blob = BlobOperationsService.upload_blob(obj.table.app_id, obj.id, StringIO.new(file))
					etag = blob.properties[:etag]
					etag = etag[1...etag.size-1]
				rescue Exception => e
					error["code"] = 4
					@errors.push(error)
					return @errors
				end

				# Update or create the properties
				if !ext_prop
					ext_prop = Property.new(table_object_id: obj.id, name: "ext", value: ext)
				else
					ext_prop.value = ext
				end

				if !etag_prop
					etag_prop = Property.new(table_object_id: obj.id, name: "etag", value: etag)
				else
					etag_prop.value = etag
				end

				if !size_prop
					size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)
				else
					size_prop.value = file_size
				end

				if !type_prop
					type_prop = Property.new(table_object_id: obj.id, name: "type", value: type)
				else
					type_prop.value = type
				end

				# Update the used storage
				update_used_storage(obj.user.id, obj.table.app_id, file_size_diff)

				# Save the properties
				if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
					error["code"] = 5
					@errors.push(error)
					return @errors
				end

				return obj
			elsif command[0].to_s == "TableObjectUserAccess.create"	# table_object_id, user_id, table_alias
				# Check if there is already an TableObjectUserAccess object
				error = Hash.new
				table_object_id = execute_command(command[1], vars)
				user_id = execute_command(command[2], vars)
				table_alias = execute_command(command[3], vars)

				if table_object_id.is_a?(String)
					# Get the id of the table object
					obj = TableObject.find_by(uuid: table_object_id)

					if !obj
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					table_object_id = obj.id
				end

				# Try to find the table
				table = Table.find_by_id(table_alias)
				if !table
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Find the access and return it
				access = TableObjectUserAccess.find_by(table_object_id: table_object_id, user_id: user_id, table_alias: table_alias)

				if !access
					access = TableObjectUserAccess.new(table_object_id: table_object_id, user_id: user_id, table_alias: table_alias)
					access.save
				end

				return access
			elsif command[0].to_s == "Collection.add_table_object"	# collection_name, table_object_id
				collection_name = execute_command(command[1], vars)
				table_object_id = execute_command(command[2], vars)

				if table_object_id.is_a?(String)
					# Get the table object by uuid
					obj = TableObject.find_by_uuid(table_object_id)
				else
					# Get the table object by id
					obj = TableObject.find_by_id(table_object_id)
				end

				if !obj
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Try to find the collection
				collection = Collection.find_by(name: collection_name, table: obj.table)

				if !collection
					# Create the collection
					collection = Collection.new(name: collection_name, table: obj.table)
					collection.save
				end

				# Create a TableObjectCollection object
				obj_collection = TableObjectCollection.new(table_object: obj, collection: collection)
				obj_collection.save
			elsif command[0].to_s == "Collection.remove_table_object"	# collection_name, table_object_id
				collection_name = execute_command(command[1], vars)
				table_object_id = execute_command(command[2], vars)

				if table_object_id.is_a?(String)
					# Get the table object by uuid
					obj = TableObject.find_by_uuid(table_object_id)
				else
					# Get the table object by id
					obj = TableObject.find_by_id(table_object_id)
				end

				if !obj
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Find the collection
				collection = Collection.find_by(name: collection_name, table: obj.table)

				if !collection
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				# Find the TableObjectCollection
				obj_collection = TableObjectCollection.find_by(table_object: obj, collection: collection)

				if obj_collection
					obj_collection.destroy!
				end
			elsif command[0].to_s == "Collection.get_table_objects"	# table_id, collection_name
				table_id = execute_command(command[1], vars)
				collection_name = execute_command(command[2], vars)

				# Try to find the table
				table = Table.find_by_id(table_id)

				if !table
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				# Try to find the collection
				collection = Collection.find_by(name: collection_name, table: table)

				return collection.table_objects.to_a if collection
				return Array.new
			elsif command[0].to_s == "TableObject.find_by_property"	# user_id, table_id, property_name, property_value, exact = true
				all_user = command[1] == :* 
				user_id = all_user ? -1 : execute_command(command[1], vars)
				table_id = execute_command(command[2], vars)
				property_name = execute_command(command[3], vars)
				property_value = execute_command(command[4], vars)
				exact = command[5] != nil ? execute_command(command[5], vars) : true

				objects = Array.new

				if all_user
					TableObject.where(table_id: table_id).each do |table_object|
						if exact
							# Look for the exact property value
							property = Property.find_by(table_object: table_object, name: property_name, value: property_value)
							objects.push(table_object) if property
						else
							# Look for the properties that contain the property value
							properties = Property.where(table_object: table_object, name: property_name)

							contains_value = false
							properties.each do |prop|
								if prop.value.include? property_value
									contains_value = true
									break
								end
							end
							objects.push(table_object) if contains_value
						end
					end
				else
					TableObject.where(user_id: user_id, table_id: table_id).each do |table_object|
						if exact
							# Look for the exact property value
							property = Property.find_by(table_object: table_object, name: property_name, value: property_value)
							objects.push(table_object) if property
						else
							# Look for properties that contain the property value
							properties = Property.where(table_object: table_object, name: property_name)
	
							contains_value = false
							properties.each do |prop|
								if prop.value.include? property_value
									contains_value = true
									break
								end
							end
							objects.push(table_object) if contains_value
						end
					end
				end

				return objects

			# Command is an expression
			elsif command[1] == :==
				execute_command(command[0], vars) == execute_command(command[2], vars)
			elsif command[1] == :!=
				execute_command(command[0], vars) != execute_command(command[2], vars)
			elsif command[1] == :>
				execute_command(command[0], vars) > execute_command(command[2], vars)
			elsif command[1] == :<
				execute_command(command[0], vars) < execute_command(command[2], vars)
			elsif command[1] == :+ || command[1] == :-
				if execute_command(command[0], vars).class == Integer
					result = 0
				elsif execute_command(command[0], vars).class == String
					result = ""
				end

				i = 0
				while command[i]
					if command[i - 1] == :- && result.class == Integer
						result -= execute_command(command[i], vars)
					else
						# Add the next part to the result
						if result.class == String
							result += execute_command(command[i], vars).to_s
						else
							result += execute_command(command[i], vars)
						end
					end

					i += 2
				end
				result
			elsif command[1] == :and || command[1] == :or
				result = execute_command(command[0], vars)
				i = 2
				
				while command[i]
					if command[i - 1] == :and
						result = execute_command(command[i], vars) && result
					elsif command[i - 1] == :or
						result = execute_command(command[i], vars) || result
					end

					i += 2
				end

				return result
			elsif command[0] == :!
				return !execute_command(command[1], vars)
			elsif command[0].to_s.include?('.')
				# Get the value of the variable
				parts = command[0].to_s.split('.')
				function_name = parts.pop
				var = parts.size == 1 ? vars[parts[0]] : execute_command(parts.join('.'), vars)
				
				if var.class == Array
					if function_name == "push"
						i = 1
						while command[i]
							result = execute_command(command[i], vars)
							var.push(result) if result != nil
							i += 1
						end
					elsif function_name == "contains"
						return var.include?(execute_command(command[1], vars))
					end
				elsif var.class == String
					if function_name == "split"
						return var.split(execute_command(command[1], vars))
					elsif function_name == "contains"
						return var.include?(execute_command(command[1], vars))
					end
				end
			else
				result = nil
				command.each do |c|
					result = execute_command(c, vars)
				end
				return result
			end
		elsif !!command == command
			# Command is boolean
			return command
		elsif command.class == String && command.size == 1
			return command
		elsif command.to_s.include?('.')
			# Return the value of the hash
			parts = command.to_s.split('.')
			last_part = parts.pop
			var = execute_command(parts.join('.').to_sym, vars)

			if last_part == "class"
				return var.class.to_s
			elsif var.class == Hash
				# Access index of array in hash
				if last_part.include?('#')
					parts = last_part.split('#')
					last_part = parts[0]
					int = (Integer(parts[1]) rescue nil)

					if var[last_part].class == Array && int
						return var[last_part][int]
					end
				end

				return var[last_part]
			elsif var.class == Array
				if last_part == "length"
					return var.count
				end
			elsif var.class == String
				if last_part == "length"
					return var.length
				elsif last_part == "upcase"
					return var.upcase
				elsif last_part == "downcase"
					return var.downcase
				end
			elsif var.class == User
				return var[last_part]
			elsif var.class == Table
				if last_part == "table_objects"
					return var.table_objects.to_a
				else
					return var[last_part]
				end
			elsif var.class == TableObject
				if last_part == "properties"
					return var.properties
				else
					return var[last_part]
				end
			elsif var.class.to_s == "Property::ActiveRecord_Associations_CollectionProxy"
				props = var.where(name: last_part)
				return props[0].value if props.count > 0
				return nil
			end
		elsif command.to_s.include?('#')
			parts = command.to_s.split('#')
			var = vars[parts.first]

			if var.class == Array
				int = (Integer(parts[1]) rescue nil)

				if int
					return var[int]
				elsif vars[parts[1]]
					return var[vars[parts[1]]]
				else
					return nil
				end
			end
		elsif command.class == Symbol
			return vars[command.to_s] if vars.key?(command.to_s)
			return nil
		else
			return command
		end
	end

	def break_execution
		@execution_stopped = true
	end

	public
	def create_api
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		app_id = params["id"]

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
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)
			name = body["name"]

			ValidationService.raise_validation_error(ValidationService.validate_name_missing(name))
			ValidationService.raise_validation_error(ValidationService.validate_name_for_api_too_short(name))
			ValidationService.raise_validation_error(ValidationService.validate_name_for_api_too_long(name))

			# Create the api
			api = Api.new(app: app, name: name)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(api.save))

			result = api.attributes
			result["endpoints"] = []
			result["functions"] = []
			result["errors"] = []

			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_api
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		api_id = params["id"]

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

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, api.app))

			# Return the api
			result = api.attributes
			result["endpoints"] = api.api_endpoints
			result["functions"] = api.api_functions
			result["errors"] = api.api_errors

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_api_endpoint
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			path = body["path"]
			method = body["method"]
			commands = body["commands"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_path_missing(path),
				ValidationService.validate_method_missing(method),
				ValidationService.validate_commands_missing(commands)
			])

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_path_too_short(path),
				ValidationService.validate_path_too_long(path),
				ValidationService.validate_method_not_valid(method),
				ValidationService.validate_commands_too_short(commands),
				ValidationService.validate_commands_too_long(commands)
			])

			# Create the api endpoint
			endpoint = ApiEndpoint.new(api: api, path: path, method: method.upcase, commands: commands)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(endpoint.save))

			render json: endpoint.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_endpoint
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			path = body["path"]
			method = body["method"]
			commands = body["commands"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_path_missing(path),
				ValidationService.validate_method_missing(method),
				ValidationService.validate_commands_missing(commands)
			])

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_path_too_short(path),
				ValidationService.validate_path_too_long(path),
				ValidationService.validate_method_not_valid(method),
				ValidationService.validate_commands_too_short(commands),
				ValidationService.validate_commands_too_long(commands)
			])

			# Try to find the api endpoint by path and method
			endpoint = ApiEndpoint.find_by(api: api, path: path, method: method.upcase)

			if endpoint
				# Update the existing endpoint
				endpoint.commands = commands
			else
				# Create a new endpoint
				endpoint = ApiEndpoint.new(api: api, path: path, method: method.upcase, commands: commands)
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(endpoint.save))

			render json: endpoint.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_api_function
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			name = body["name"]
			params = body["params"]
			commands = body["commands"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_missing(name),
				ValidationService.validate_commands_missing(commands)
			])

			validations = [
				ValidationService.validate_name_for_api_function_too_short(name),
				ValidationService.validate_name_for_api_function_too_long(name)
			]

			validations.push(ValidationService.validate_params_too_long(params)) if params

			validations.push(
				ValidationService.validate_commands_too_short(commands),
				ValidationService.validate_commands_too_long(commands)
			)

			ValidationService.raise_multiple_validation_errors(validations)

			# Create the api function
			function = ApiFunction.new(api: api, name: name, params: params, commands: commands)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(function.save))

			render json: function.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_function
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			name = body["name"]
			params = body["params"]
			commands = body["commands"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_name_missing(name),
				ValidationService.validate_commands_missing(commands)
			])

			validations = [
				ValidationService.validate_name_for_api_function_too_short(name),
				ValidationService.validate_name_for_api_function_too_long(name)
			]

			validations.push(ValidationService.validate_params_too_long(params)) if params

			validations.push(
				ValidationService.validate_commands_too_short(commands),
				ValidationService.validate_commands_too_long(commands)
			)

			ValidationService.raise_multiple_validation_errors(validations)

			# Try to find the api function by name
			function = ApiFunction.find_by(api: api, name: name)

			if function
				# Update the existing function
				function.params = params
				function.commands = commands
			else
				# Create a new function
				function = ApiFunction.new(api: api, name: name, params: params, commands: commands)
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(function.save))

			render json: function.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_api_error
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			code = body["code"]
			message = body["message"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_code_missing(code),
				ValidationService.validate_message_missing(message)
			])

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_message_too_short(message),
				ValidationService.validate_message_too_long(message),
				ValidationService.validate_code_not_valid(code)
			])

			# Create the api error
			error = ApiError.new(api: api, code: code, message: message)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(error.save))
			
			render json: error.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_error
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			code = body["code"]
			message = body["message"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_code_missing(code),
				ValidationService.validate_message_missing(message)
			])

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_message_too_short(message),
				ValidationService.validate_message_too_long(message),
				ValidationService.validate_code_not_valid(code)
			])

			# Try to find the api error by code
			error = ApiError.find_by(api: api, code: code)

			if error
				# Update the existing error
				error.message = message
			else
				# Create a new error
				error = ApiError.new(api: api, code: code, message: message)
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(error.save))

			render json: error.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_errors
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			errors = body["errors"]
			ValidationService.raise_validation_error(ValidationService.validate_errors_missing(errors))

			errors.each do |error|
				code = error["code"]
				message = error["message"]

				next if !ValidationService.validate_code_missing(code)[:success] || !ValidationService.validate_message_missing(message)[:success]
				next if !ValidationService.validate_message_too_short(message)[:success] || !ValidationService.validate_message_too_long(message)[:success] || !ValidationService.validate_code_not_valid(code)[:success]

				# Try to find the api error by code
				api_error = ApiError.find_by(api: api, code: code)

				if api_error
					# Update the existing error
					api_error.message = message
				else
					# Create a new error
					api_error = ApiError.new(api: api, code: code, message: message)
				end

				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(api_error.save))
			end

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_env_vars
		auth = request.headers["HTTP_AUTHORIZATION"] ? request.headers["HTTP_AUTHORIZATION"].split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			api_key = auth.split(",")[0]

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(api.app, dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)

			body.each do |key, value|
				class_name = get_env_class_name(value)

				if class_name.start_with?('array')
					value = value.join(',')
				end

				# Try to find the api env var by name
				env = ApiEnvVar.find_by(api: api, name: key)

				if env
					# Update the existing env var
					env.value = value.to_s
					env.class_name = class_name
				else
					# Create a new env var
					env = ApiEnvVar.new(api: api, name: key, value: value.to_s, class_name: class_name)
				end

				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(env.save))
			end

			render json: {}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	private
	def get_env_class_name(value)
		class_name = "string"

		if value.is_a?(TrueClass) || value.is_a?(FalseClass)
			class_name = "bool"
		elsif value.is_a?(Integer)
			class_name = "int"
		elsif value.is_a?(Float)
			class_name = "float"
		elsif value.is_a?(Array)
			content_class_name = get_env_class_name(value[0])
			class_name = "array:#{content_class_name}"
		end

		return class_name
	end

	def convert_env_value(class_name, value)
		if class_name == "bool"
			return value == "true"
		elsif class_name == "int"
			return value.to_i
		elsif class_name == "float"
			return value.to_f
		elsif class_name.include?(':')
			parts = class_name.split(':')

			if parts[0] == "array"
				array = Array.new

				value.split(',').each do |val|
					array.push(convert_env_value(parts[1], val))
				end

				return array
			else
				return value
			end
		end
	end
end