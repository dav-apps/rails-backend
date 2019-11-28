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
			api.api_endpoints.each do |endpoint|
				if endpoint.path == path
					api_endpoint = endpoint
				end
			end

			ValidationService.raise_validation_error(ValidationService.validate_api_endpoint_does_not_exist(api_endpoint))

			# Parse the endpoint commands
			parser = Sexpistol.new
			parser.ruby_keyword_literals = true
			ast = parser.parse_string(api_endpoint.commands)

			@vars = Hash.new
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
			add_var(exp)
		elsif exp[0] == :if && exp[3] == :else
			resolve_if(exp)
		elsif exp[0] == :log
			puts resolve_expression(exp[1])
		else
			exp.each do |command|
				execute_exp(command)
			end
		end
	end

	def add_var(exp)
		# e.g. var bla true
		@vars[exp[1]] = resolve_expression(exp[2])
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
			end
		elsif !!exp == exp
			# exp is boolean
			exp
		else
			# Find the variable
			var = get_var(exp)
			return var if var

			# Return the expression as string
			exp
		end
	end
end