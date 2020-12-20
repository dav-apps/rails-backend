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

	def self.get_total_storage(plan, confirmed)
		storage_unconfirmed = 1000000000 	# 1 GB
      storage_on_free_plan = 2000000000 	# 2 GB
      storage_on_plus_plan = 15000000000 	# 15 GB
      storage_on_pro_plan = 50000000000   # 50 GB

		if !confirmed
			return storage_unconfirmed
      elsif plan == 1 # User is on Plus plan
			return storage_on_plus_plan
		elsif plan == 2
			return storage_on_pro_plan
		else
			return storage_on_free_plan
		end
	end
	
	def self.update_used_storage(user, app, storage_change)
		update_used_storage_of_user(user, storage_change)
		update_used_storage_of_app(user, app, storage_change)
	end
	
	def self.update_used_storage_of_user(user, storage_change)
		return if user.nil?

		user.used_storage = user.used_storage += storage_change
		user.save
	end

	def self.update_used_storage_of_app(user, app, storage_change)
		users_app = UsersAppDelegate.find_by(user_id: user.id, app_id: app.id)
		return if users_app.nil?

		users_app.used_storage = users_app.used_storage += storage_change
		users_app.save
	end
end