class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		path = params[:path]

		begin
			# Get the api
			@api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(@api))

			# Find the correct api endpoint
			api_endpoint = nil
			@vars = Hash.new
			@functions = Hash.new
			@errors = Array.new

			method = 0
			case request.method
			when "POST"
				method = 1
			when "PUT"
				method = 2
			when "DELETE"
				method = 3
			end

			@api.api_endpoints.where(method: method).each do |endpoint|
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

			ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_does_not_exist(api_endpoint))

			# Parse the endpoint commands
			parser = Sexpistol.new
			parser.ruby_keyword_literals = true
			ast = parser.parse_string(api_endpoint.commands)

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
	def execute_command(command, args)
		return nil if @execution_stopped
		return nil if @errors.count > 0
		vars = args.deep_dup
		if command.class == Array
			# Command is a function call
			if command[0].class == Array
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

					parts.each do |part|
						current_var = current_var[part]
						return nil if current_var.class != Hash
					end

					current_var[last_part] = execute_command(command[2], vars)
				else
					args[command[1].to_s] = execute_command(command[2], vars)
				end
			elsif command[0] == :hash
				if command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop
					current_var = vars

					parts.each do |part|
						current_var = current_var[part]
						return nil if current_var.class != Hash
					end

					current_var[last_part] = Hash.new
				else
					hash = Hash.new

					i = 1
					while command[i]
						hash[command[i][0]] = execute_command(command[i][1], vars)
						i += 1
					end
					
					return hash
				end
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
					execute_command(command[2], vars)
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
					# Add the parameters to the variables
					i = 0
					function["parameters"].each do |param|
						vars[param] = command[2][i]
						i += 1
					end

					execute_command(function["commands"], vars)
				end
			elsif command[0] == :catch
				# Execute the commands in the first argument
				execute_command(command[1], vars)

				if @errors.length > 0
					# Add the errors to the variables and execute the commands in the second argument
					vars["errors"] = Array.new

					while @errors.length > 0
						vars["errors"].push(@errors.pop)
					end

					execute_command(command[2], vars)
				end
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
					if !session || session.app_id != @api.app_id
						# Session does not exist
						error["code"] = 0
						@errors.push(error)
						return @errors
					end

					secret = session.secret
				end
				
				begin
					JWT.decode(jwt, secret, true, {algorithm: ENV['JWT_ALGORITHM']})[0]
				rescue JWT::ExpiredSignature
					# JWT expired
					error["code"] = 1
					@errors.push(error)
					return @errors
				rescue JWT::DecodeError
					# JWT decode failed
					error["code"] = 2
					@errors.push(error)
					return @errors
				rescue Exception
					# Generic error
					error["code"] = 3
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
				JSON.parse(execute_command(command[1], vars))
			elsif command[0] == :get_header
				return request.headers[command[1].to_s]
			elsif command[0] == :get_param
				return params[command[1]]
			elsif command[0] == :get_body
				if request.body.class == StringIO
					return request.body.string
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

			elsif command[0].to_s.include?('.')
				# Get the value of the variable
				var_name, function_name = command[0].to_s.split('.')
				var = vars[var_name]
				
				if var.class == Array
					if function_name == "push"
						i = 1
						while command[i]
							var.push(execute_command(command[i], vars))
							i += 1
						end
					end
				end
			
			# Command is an expression
			elsif command[1] == :==
				execute_command(command[0], vars) == execute_command(command[2], vars)
			elsif command[1] == :!=
				execute_command(command[0], vars) != execute_command(command[2], vars)
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
			else
				result = nil
				command.each do |c|
					result = execute_command(c, vars)
				end
				return result
			end
		elsif !!command == command
			# Command is boolean
			command
		elsif command.to_s.include?('.')
			# Return the value of the hash
			parts = command.to_s.split('.')
			var = vars[parts.first]

			if var.class == Hash
				last_part = parts.pop
				current_var = vars

				parts.each do |part|
					current_var = current_var[part]
					return nil if current_var.class != Hash
				end

				return current_var[last_part]
			elsif var.class == Array
				if parts[1] == "length"
					return var.count
				end
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
		else
			# Find and return the variable
			return vars[command.to_s] if vars.key?(command.to_s)

			# Return the command
			return command
		end
	end

	def break_execution
		@execution_stopped = true
	end
end