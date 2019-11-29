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

			api.api_endpoints.each do |endpoint|
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
						@vars[key.to_sym] = value
					end
					break
				end
			end

			ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_does_not_exist(api_endpoint))

			# Parse the endpoint commands
			parser = Sexpistol.new
			parser.ruby_keyword_literals = true
			ast = parser.parse_string(api_endpoint.commands)

			ast.each do |element|
				execute_exp(element)
			end

		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	private
	def execute_exp(exp)
		if exp.class == Array
			call_function(exp)
		else
			puts exp
		end
	end

	def call_function(exp)
		if exp[0] == :var
			set_var(exp[1], resolve_expression(exp[2]))
		elsif exp[0] == :if && exp[3] == :else
			resolve_if(exp)
		elsif exp[0] == :log
			puts resolve_expression(exp[1])
		elsif exp[0] == :to_int
			value = get_var(exp[1])
			set_var(exp[1], value.to_i) if value
		elsif exp[0] == :render_json
			render json: resolve_expression(exp[1]), status: resolve_expression(exp[2])
		else
			exp.each do |command|
				execute_exp(command)
			end
		end
	end

	def set_var(name, value)
		@vars[name] = value
	end

	def get_var(name)
		@vars.each do |var|
			return var[1] if var[0] == name
		end
		nil
	end

	def resolve_if(exp)
		if resolve_expression(exp[1])
			execute_exp(exp[2])
		else
			execute_exp(exp[4])
		end
	end

	def resolve_expression(exp)
		if exp.class == Array
			if exp[1] == :==
				resolve_expression(exp[0]) == resolve_expression(exp[2])
			elsif exp[1] == :!=
				resolve_expression(exp[0]) != resolve_expression(exp[2])
			elsif exp[1] == :+ || exp[1] == :-
				if resolve_expression(exp[0]).class == Integer
					result = 0
				elsif resolve_expression(exp[0]).class == String
					result = ""
				end

				i = 0
				while exp[i]
					if exp[i - 1] == :- && result.class == Integer
						result -= resolve_expression(exp[i])
					else
						# Add the next part to the result
						if result.class == String
							result += resolve_expression(exp[i]).to_s
						else
							result += resolve_expression(exp[i])
						end
					end

					i += 2
				end
				result
			end
		elsif !!exp == exp
			# exp is boolean
			exp
		else
			# Find the variable
			var = get_var(exp)
			return var if var

			# Return the expression
			exp
		end
	end
end