class ApisController < ApplicationController
	def api_call
		api_id = params[:id]
		path = params[:path]

		begin
			# Get the api
			api = Api.find_by_id(api_id)
			ValidationService.raise_validation_error(ValidationService.validate_api_does_not_exist(api))

			# Find the correct api endpoint
			api_endpoint = nil
			@vars = Hash.new

			method = 0
			case request.method
			when "POST"
				method = 1
			when "PUT"
				method = 2
			when "DELETE"
				method = 3
			end

			api.api_endpoints.where(method: method).each do |endpoint|
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
				execute_command(element)
			end

		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	private
	def execute_command(command)
		if command.class == Array
			# Command is a function call
			if command[0] == :var
				if command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop
					current_var = @vars

					parts.each do |part|
						current_var = current_var[part]
						return nil if current_var.class != Hash
					end

					current_var[last_part] = execute_command(command[2])
				else
					set_var(command[1], execute_command(command[2]))
				end
			elsif command[0] == :hash
				if command[1].to_s.include?('.')
					parts = command[1].to_s.split('.')
					last_part = parts.pop
					current_var = @vars

					parts.each do |part|
						current_var = current_var[part]
						return nil if current_var.class != Hash
					end

					current_var[last_part] = Hash.new
				else
					hash = Hash.new

					i = 1
					while command[i]
						hash[command[i][0]] = command[i][1]
						i += 1
					end
					
					return hash
				end
			elsif command[0] == :list
				list = Array.new

				i = 1
				while command[i]
					list.push(execute_command(command[i]))
					i += 1
				end

				return list
			elsif command[0] == :if && command[3] == :else
				resolve_if(command)
			elsif command[0] == :log
				result = execute_command(command[1])
				puts result
				return result
			elsif command[0] == :to_int
				return execute_command(command[1]).to_i
			elsif command[0].to_s == "#"
				# It's a comment. Ignore this command
				return nil
			elsif command[0] == :parse_json
				JSON.parse(execute_command(command[1]))
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
			elsif command[0] == :render_json
				render json: execute_command(command[1]), status: execute_command(command[2])
				break_execution
			
			# Command is an expression
			elsif command[1] == :==
				execute_command(command[0]) == execute_command(command[2])
			elsif command[1] == :!=
				execute_command(command[0]) != execute_command(command[2])
			elsif command[1] == :+ || command[1] == :-
				if execute_command(command[0]).class == Integer
					result = 0
				elsif execute_command(command[0]).class == String
					result = ""
				end

				i = 0
				while command[i]
					if command[i - 1] == :- && result.class == Integer
						result -= execute_command(command[i])
					else
						# Add the next part to the result
						if result.class == String
							result += execute_command(command[i]).to_s
						else
							result += execute_command(command[i])
						end
					end

					i += 2
				end
				result
			else
				return command
			end
		elsif !!command == command
			# Command is boolean
			command
		elsif command.to_s.include?('.')
			# Return the value of the hash
			parts = command.to_s.split('.')
			last_part = parts.pop
			current_var = @vars

			parts.each do |part|
				current_var = current_var[part]
				return nil if current_var.class != Hash
			end

			return current_var[last_part]
		else
			# Find and return the variable
			var = get_var(command)
			return var if var

			# Return the command
			command
		end
	end

	def set_var(name, value)
		@vars[name.to_s] = value
		return value
	end

	def get_var(name)
		@vars.each do |var|
			return var[1] if var[0] == name.to_s
		end
		nil
	end

	def resolve_if(exp)
		if execute_command(exp[1])
			execute_command(exp[2])
		else
			execute_command(exp[4])
		end
	end

	def break_execution
		@execution_stopped = true
	end
end