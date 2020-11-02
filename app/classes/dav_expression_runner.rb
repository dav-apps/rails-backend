class DavExpressionRunner
	def run(props)
		# Get the runtime variables
		@api = props[:api]
		@vars = props[:vars]
		@functions = Hash.new
		@errors = Array.new
		@request = props[:request]
		@response = Hash.new

		# Parse and execute the commands
		@parser = Sexpistol.new
		@parser.ruby_keyword_literals = true
		ast = @parser.parse_string(props[:commands])

		# Stop the execution of the program if this is true
		@execution_stopped = false

		# Stop the current for loop if this is true
		@break_loop = false

		ast.each do |element|
			break if @execution_stopped
			execute_command(element, @vars)
		end

		# Return the response
		return @response
	end

	def execute_command(command, vars)
		return nil if @execution_stopped
		return nil if @errors.count > 0
		return nil if @break_loop

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
					holder = nil

					parts.each do |part|
						if current_var.is_a?(Hash)
							current_var = current_var[part]
						elsif current_var.is_a?(TableObject) && part == "properties"
							current_var = current_var.properties
						elsif current_var.is_a?(TableObjectHolder) && part == "properties"
							holder = current_var
							current_var = current_var.values
						else
							return nil
						end
					end

					if current_var.is_a?(Hash)
						if holder
							prop = holder.properties.find{ |property| property.name == last_part }

							if prop
								# Update the value of the property
								prop.value = execute_command(command[2], vars)
								prop.save

								# Update the values Hash of the TableObjectHolder
								holder.values[prop.name] = prop.value

								return prop.value
							else
								# Create a new property
								prop = Property.new(table_object: holder.obj, name: last_part, value: execute_command(command[2], vars))
								prop.save
								holder.values[last_part] = prop.value
								holder.properties.push(prop)
								return prop.value
							end
						else
							current_var[last_part] = execute_command(command[2], vars)
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
					break if @break_loop

					vars[var_name.to_s] = entry
					execute_command(commands, vars)
				end

				@break_loop = false
			elsif command[0] == :break
				@break_loop = true
				return nil
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
			elsif command[0] == :log_time
				return log_time(command[1])
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
				return @request[:headers][command[1].to_s]
			elsif command[0] == :get_param
				return params[command[1]]
			elsif command[0] == :get_body
				if @request[:body].class == StringIO
					return @request[:body].string
				elsif @request[:body].class == Tempfile
					return @request[:body].read
				else
					return @request[:body]
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
				result = execute_command(command[1], vars)
				status = execute_command(command[2], vars)

				@response[:data] = result
				@response[:status] = status == nil ? 200 : status
				@response[:file] = false

				@execution_stopped = true
			elsif command[0] == :render_file
				result = execute_command(command[1], vars)
				type = execute_command(command[2], vars)
				filename = execute_command(command[3], vars)
				status = execute_command(command[4], vars)

				@response[:data] = result
				@response[:status] = status == nil ? 200 : status
				@response[:file] = true
				@response[:headers] = {"Content-Length" => result == nil ? 0 : result.size.to_s}
				@response[:type] = type
				@response[:filename] = filename

				@execution_stopped = true
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
				end

				objects = table.table_objects.where(user_id: execute_command(command[2], vars).to_i).to_a
				
				holders = Array.new
				objects.each{ |obj| holders.push(TableObjectHolder.new(obj)) }

				return holders
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
				return TableObjectHolder.new(obj)
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
				free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

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
				UtilsService.update_used_storage(user.id, table.app_id, file_size)

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

				return TableObjectHolder.new(obj)
			elsif command[0].to_s == "TableObject.get"	# uuid
				obj = TableObject.find_by(uuid: execute_command(command[1], vars))
				return nil if !obj

				# Check if the table of the table object belongs to the same app as the api
				if obj.table.app != @api.app
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				return TableObjectHolder.new(obj)
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

				return TableObjectHolder.new(obj)
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
				free_storage = UtilsService.get_total_storage(user.plan, user.confirmed) - user.used_storage

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
				UtilsService.update_used_storage(obj.user.id, obj.table.app_id, file_size_diff)

				# Save the properties
				if !ext_prop.save || !etag_prop.save || !size_prop.save || !type_prop.save
					error["code"] = 5
					@errors.push(error)
					return @errors
				end

				return TableObjectHolder.new(obj)
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
				error = Hash.new
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

				# Try to find the TableObjectCollection
				obj_collection = TableObjectCollection.find_by(table_object: obj, collection: collection)

				if !obj_collection
					# Create the TableObjectCollection
					obj_collection = TableObjectCollection.new(table_object: obj, collection: collection)
					obj_collection.save
				end
			elsif command[0].to_s == "Collection.remove_table_object"	# collection_name, table_object_id
				error = Hash.new
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
				error = Hash.new
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

				if collection
					holders = Array.new
					collection.table_objects.each{ |obj| holders.push(TableObjectHolder.new(obj)) }

					return holders
				end

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

				holders = Array.new
				objects.each{ |obj| holders.push(TableObjectHolder.new(obj)) }

				return holders
			elsif command[0].to_s == "Purchase.get_table_object"	# purchase_id, user_id
				error = Hash.new
				purchase_id = execute_command(command[1], vars)
				user_id = execute_command(command[2], vars)

				purchase = Purchase.find_by_id(purchase_id)

				if !purchase
					error["code"] = 0
					@errors.push(error)
					return @errors
				end

				user = User.find_by_id(user_id)

				if !user
					error["code"] = 1
					@errors.push(error)
					return @errors
				end

				if purchase.user != user
					error["code"] = 2
					@errors.push(error)
					return @errors
				end

				if !purchase.completed
					error["code"] = 3
					@errors.push(error)
					return @errors
				end

				return TableObjectHolder.new(purchase.table_object)
			elsif command[0].to_s == "Purchase.find_by_user_and_table_object"		# user_id, table_object_id
				user_id = execute_command(command[1], vars)
				table_object_id = execute_command(command[2], vars)

				if table_object_id.class == Integer
					# table_object_id is id
					return Purchase.find_by(user_id: user_id, table_object_id: table_object_id, completed: true)
				else
					# table_object_id is uuid
					table_object = TableObject.find_by(uuid: table_object_id)
					
					return nil if !table_object
					return Purchase.find_by(user_id: user_id, table_object_id: table_object.id, completed: true)
				end

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
					elsif function_name == "join"
						return "" if var.size == 0

						separator = execute_command(command[1], vars)
						result = var[0]

						for i in 1..var.size - 1 do
							result = result + separator + var[i]
						end

						return result
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
				elsif last_part == "reverse"
					return var.reverse
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
			elsif var.class == TableObjectHolder
				return var.values if last_part == "properties"
				return var.obj[last_part]
			elsif var.class == Purchase
				return var[last_part]
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

	def log_time(message = nil)
		current = Time.new
		@start = current if @start == nil

		time_diff = (current - @start).in_milliseconds

		puts "---------------------"
		if message == nil
			puts "#{time_diff.to_s} ms"
		else
			puts "#{message}: #{time_diff.to_s} ms"
		end
		puts "---------------------"

		@start = current
		return time_diff
	end
end