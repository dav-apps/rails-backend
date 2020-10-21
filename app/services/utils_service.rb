class UtilsService
	def self.get_env_class_name(value)
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

	def self.convert_env_value(class_name, value)
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