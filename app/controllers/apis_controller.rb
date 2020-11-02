class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		path = params[:path]

		begin
			# Get the api
			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))

			# Find the correct api endpoint
			api_endpoint = api.api_endpoints.find_by(method: request.method, path: path)
			vars = Hash.new

			if !api_endpoint
				# Try to find an endpoint by checking the endpoints with variables in the url
				api.api_endpoints.where(method: request.method).each do |endpoint|
					path_parts = endpoint.path.split('/')
					url_parts = path.split('/')
					next if path_parts.count != url_parts.count

					url_vars = Hash.new
					cancelled = false
					i = -1

					path_parts.each do |part|
						i += 1
						
						if url_parts[i] == part
							next
						elsif part[0] == ':'
							url_vars[part[1..part.size]] = url_parts[i]
							next
						end

						cancelled = true
						break
					end

					if !cancelled
						api_endpoint = endpoint
						url_vars.each do |key, value|
							vars[key] = value
						end
						break
					end
				end
			end

			ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_does_not_exist(api_endpoint))

			# Get the url params
			request.query_parameters.each do |key, value|
				vars[key.to_s] = value
			end

			cache_response = false

			if api_endpoint.caching && request.headers["Authorization"] == nil && request.method.downcase == "get"
				# Try to find a cache of the endpoint with this combination of params
				cache = nil
				cache_params = vars.sort.to_h
				
				api_endpoint.api_endpoint_request_caches.each do |request_cache|
					request_cache_params = request_cache.api_endpoint_request_cache_params
					next if cache_params.size != request_cache_params.size

					# Convert the params into a hash
					request_cache_params_hash = Hash.new
					request_cache_params.each { |param| request_cache_params_hash[param.name] = param.value }

					next if request_cache_params_hash != cache_params
					cache = request_cache
					break
				end

				if cache != nil
					# Return the cached response
					render json: cache.response, status: 200
					return
				else
					# Copy the current vars as the params for the cache
					cache_response = true
				end
			end

			# Get the environment variables
			vars["env"] = Hash.new
			api.api_env_vars.each do |env_var|
				vars["env"][env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
			end

			# Get the headers
			headers = Hash.new
			headers["Authorization"] = request.headers["Authorization"]
			headers["Content-Type"] = request.headers["Content-Type"]

			runner = DavExpressionRunner.new
			result = runner.run({
				api: api,
				vars: vars,
				commands: api_endpoint.commands,
				request: {
					headers: headers,
					body: request.body
				}
			})

			if cache_response && result[:status] == 200
				# Save the response in the cache
				cache = ApiEndpointRequestCache.new(api_endpoint: api_endpoint, response: result[:data].to_json)

				if cache.save
					# Create the cache params
					cache_params.each do |var|
						# var = ["key", "value"]
						param = ApiEndpointRequestCacheParam.new(api_endpoint_request_cache: cache, name: var[0], value: var[1])
						param.save
					end
				end
			end

			# Send the response
			if result[:file]
				# Send the file
				result[:headers].each { |key, value| response.set_header(key, value) }
				send_data(result[:data], type: result[:type], filename: result[:filename], status: result[:status])
			else
				# Send the json
				render json: result[:data], status: result[:status]
			end
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_api
		jwt, session_id = get_jwt_from_header(get_authorization_header)
		app_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		jwt, session_id = get_jwt_from_header(get_authorization_header)
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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
			caching = body["caching"]

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
			endpoint.caching = caching if caching != nil
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(endpoint.save))

			render json: endpoint.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def set_api_endpoint
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
			caching = body["caching"]

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
				endpoint.caching = caching if caching != nil
			else
				# Create a new endpoint
				endpoint = ApiEndpoint.new(api: api, path: path, method: method.upcase, commands: commands)
				endpoint.caching = caching if caching != nil
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(endpoint.save))

			render json: endpoint.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def create_api_function
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
		auth = get_authorization_header ? get_authorization_header.split(' ').last : nil
		api_id = params["id"]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(get_content_type_header))

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
				class_name = UtilsService.get_env_class_name(value)

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
end