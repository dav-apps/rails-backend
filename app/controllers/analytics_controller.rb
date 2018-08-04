class AnalyticsController < ApplicationController
	
	def create_event_log
		api_key = params["api_key"]
		name = params["name"]
		app_id = params["app_id"]
		save_country = params["save_country"] == "true"

		begin
			api_key_validation = ValidationService.validate_api_key_missing(api_key)
			name_validation = ValidationService.validate_name_missing(name)
			app_id_validation = ValidationService.validate_app_id_missing(app_id)
			errors = Array.new

			if !api_key_validation[:success]
				errors.push(api_key_validation)
			end

			if !name_validation[:success]
				errors.push(name_validation)
			end

			if !app_id_validation[:success]
				errors.push(app_id_validation)
			end

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			if request.body.string.length > 0
				ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
			end

			# Check if the event with the name already exists
			event = Event.find_by(name: name, app_id: app_id)

			if !event
				# Validate properties of the new event
				ValidationService.raise_validation_error(ValidationService.validate_name_too_long(name))
				ValidationService.raise_validation_error(ValidationService.validate_name_too_short(name))

				# Create the new event
				event = Event.new(name: name, app_id: app_id)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event.save))
			end

			object = ValidationService.parse_json(request.body.string)
			object.each do |key, value|
				if value
					if value.length > 0
						ValidationService.raise_validation_error(ValidationService.validate_property_name_too_short(key))
						ValidationService.raise_validation_error(ValidationService.validate_property_value_too_short(value))
						ValidationService.raise_validation_error(ValidationService.validate_property_name_too_long(key))
						ValidationService.raise_validation_error(ValidationService.validate_property_value_too_long(value))
					end
				end
			end

			# Create the event logs
			event_log = EventLog.new(event_id: event.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event_log.save))

			properties = Hash.new

			object.each do |key, value|
				if value
					if value.length > 0
						event_log_property = EventLogProperty.new(event_log_id: event_log.id, name: key, value: value)
						ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event_log_property.save))
						properties[key] = value
					end
				end
			end

			if save_country
				# Get the country code and save it as event_log_property
				ip = request.remote_ip

				begin
					country_key = "country"
					country_code = JSON.parse(IpinfoIo::lookup(ip).body)["country"]

					ip_property = EventLogProperty.new(event_log_id: event_log.id, name: country_key, value: country_code)
					if ip_property.save
						properties[country_key] = country_code
					end
				rescue StandardError => e
					puts e
				end
			end

			result = event_log.attributes
			result["properties"] = properties

			render json: result, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)			
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"] 
		end
	end

	def get_event
		event_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		start_timestamp = params["start"]
		end_timestamp = params["end"]

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(event_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(ValidationService.validate_dev_does_not_exist(dev)))

			event = Event.find_by(id: event_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))

			app = App.find_by_id(event.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Return the data
			result = event.attributes
									
			logs = Array.new
			event.event_logs.each do |log|
				# Check if the log was created within the specified timeframe
				unix_time = DateTime.parse(log.created_at.to_s).strftime("%s")

				if start_timestamp
					if unix_time < start_timestamp
						next
					end
				end

				if end_timestamp
					if unix_time > end_timestamp
						next
					end
				end

				log_hash = Hash.new
				properties = Hash.new

				log.event_log_properties.each do |property|
					properties[property.name] = property.value
				end

				log_hash["id"] = log.id
				log_hash["created_at"] = log.created_at
				log_hash["properties"] = properties
				logs.push(log_hash)
			end

			result["logs"] = logs
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)			
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"] 
		end
	end

	def get_event_by_name
		name = params["name"]
		app_id = params["app_id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		start_timestamp = params["start"]
		end_timestamp = params["end"]

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			app_id_validation = ValidationService.validate_app_id_missing(app_id)
			name_validation = ValidationService.validate_name_missing(name)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]
			errors.push(app_id_validation) if !app_id_validation[:success]
			errors.push(name_validation) if !name_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			event = Event.find_by(name: name, app: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))

			# Make sure this is called from the website
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Return the data
			result = event.attributes
			
			logs = Array.new
			event.event_logs.each do |log|
				# Check if the log was created within the specified timestamp
				unix_time = DateTime.parse(log.created_at.to_s).strftime("%s")

				if start_timestamp
					if unix_time < start_timestamp
						next
					end
				end

				if end_timestamp
					if unix_time > end_timestamp
						next
					end
				end

				log_hash = Hash.new
				properties = Hash.new

				log.event_log_properties.each do |property|
					properties[property.name] = property.value
				end

				log_hash["id"] = log.id
				log_hash["created_at"] = log.created_at
				log_hash["properties"] = properties
				logs.push(log_hash)
			end

			result["logs"] = logs
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def update_event
		event_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(event_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			event = Event.find_by_id(event_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))
			
			app = App.find_by_id(event.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Only accept application/json as Content-Type
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			object = ValidationService.parse_json(request.body.string)
			name = object["name"]

			if name
				ValidationService.raise_validation_error(ValidationService.validate_name_too_short(name))
				ValidationService.raise_validation_error(ValidationService.validate_name_too_long(name))
				ValidationService.raise_validation_error(ValidationService.validate_event_name_taken(name, event.name, app.id))
			end

			event.name = name
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event.save))

			result = event.attributes
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end
	
	def delete_event
		event_id = params["id"]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
		
		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(event_id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			event = Event.find_by_id(event_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))
			
			app = App.find_by_id(event.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			event.destroy!

			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_app
		id = params[:id]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			id_validation = ValidationService.validate_id_missing(id)
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
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))

			# Make sure this is called from the website
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			# Return the data
			users = Array.new
			result = Hash.new
			
			app.users_apps.each do |users_app|
				hash = Hash.new
				hash["id"] = users_app.user_id
				hash["started_using"] = users_app.created_at

				users.push(hash)
			end

			result["users"] = users
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def get_users
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		begin
			jwt_validation = ValidationService.validate_jwt_missing(jwt)
			errors = Array.new

			errors.push(jwt_validation) if !jwt_validation[:success]

			if errors.length > 0
				raise RuntimeError, errors.to_json
			end

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_users_dev_is_dev(user, dev))

			# Return the data
			users = Array.new
			result = Hash.new

			User.all.each do |user|
				hash = Hash.new

				hash["id"] = user.id
				hash["created_at"] = user.created_at
				hash["updated_at"] = user.updated_at
				hash["confirmed"] = user.confirmed
				hash["plan"] = user.plan

				apps = Array.new
				user.apps.each do |app|
					app_hash = Hash.new
					app_hash["id"] = app.id
					app_hash["name"] = app.name
					apps.push(app_hash)
				end

				hash["apps"] = apps

				users.push(hash)
			end

			result["users"] = users
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end
end