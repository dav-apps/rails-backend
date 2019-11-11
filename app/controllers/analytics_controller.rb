class AnalyticsController < ApplicationController
	def create_event_log
		begin
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))
			body = ValidationService.parse_json(request.body.string)

			api_key = body["api_key"]
			app_id = body["app_id"]
			name = body["name"]
			browser_name = body["browser_name"]
			browser_version = body["browser_version"]
			os_name = body["os_name"]
			os_version = body["os_version"]
			country = body["country"]

			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_api_key_missing(api_key),
				ValidationService.validate_app_id_missing(app_id),
				ValidationService.validate_name_missing(name),
				ValidationService.validate_browser_name_missing(browser_name),
				ValidationService.validate_browser_version_missing(browser_version),
				ValidationService.validate_os_name_missing(os_name),
				ValidationService.validate_os_version_missing(os_version)
			])
			
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(app, dev))

			# If no country is given, get the country by the IP address of the client
			if !country
				ip = request.remote_ip

				begin
					handler = IPinfo::create(ENV["IPINFO_ACCESS_TOKEN"])
					country = handler.details(ip).all[:country]
				rescue StandardError => e
					puts e
				end
			end

			# Check if the event with the name already exists
			event = Event.find_by(name: name, app_id: app_id)

			if !event
				# Validate properties of the new event
				ValidationService.raise_validation_error(ValidationService.validate_event_name_too_short(name))
				ValidationService.raise_validation_error(ValidationService.validate_event_name_too_long(name))

				# Create the new event
				event = Event.new(name: name, app_id: app_id)
				ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event.save))
			end

			# Create the event log
			event_log = StandardEventLog.new(
				event_id: event.id, 
				browser_name: browser_name,
				browser_version: browser_version,
				os_name: os_name,
				os_version: os_version,
				country: country
			)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event_log.save))

			# Return the event log
			render json: event_log.attributes, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_event
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		event_id = params["id"]
		start_timestamp = params["start"] ? DateTime.strptime(params["start"],'%s') : (Time.now - 1.month)
		end_timestamp = params["end"] ? DateTime.strptime(params["end"],'%s') : Time.now
		period = params["period"] ? params["period"].to_i : 1

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(ValidationService.validate_dev_does_not_exist(dev)))

			event = Event.find_by_id(event_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))

			app = App.find_by_id(event.app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			if period < 0
				period = 0
			elsif period > 3
				period = 3
			end

			# Return the data
			result = event.attributes
			summaries = Array.new

			event.standard_event_summaries.where("period = ? AND time > ? AND time < ?", period, start_timestamp, end_timestamp).each do |summary|
				# Add the summary to the array
				log = {
					time: summary.time,
					total: summary.total
				}

				os = Array.new
				summary.event_summary_os_counts.each do |obj|
					os.push({
						name: obj.name,
						version: obj.version,
						count: obj.count
					})
				end

				browser = Array.new
				summary.event_summary_browser_counts.each do |obj|
					browser.push({
						name: obj.name,
						version: obj.version,
						count: obj.count
					})
				end

				country = Array.new
				summary.event_summary_country_counts.each do |obj|
					country.push({
						country: obj.country,
						count: obj.count
					})
				end

				log["os"] = os
				log["browser"] = browser
				log["country"] = country
				summaries.push(log)
			end
			
			result["period"] = period
			result["summaries"] = summaries
			
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_event_by_name
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		name = params["name"]
		app_id = params["app_id"]
		start_timestamp = params["start"] ? DateTime.strptime(params["start"],'%s') : (Time.now - 1.month)
		end_timestamp = params["end"] ? DateTime.strptime(params["end"],'%s') : Time.now
		period = params["period"] ? params["period"].to_i : 1

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_name_missing(name),
				ValidationService.validate_app_id_missing(app_id)
			])

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(ValidationService.validate_dev_does_not_exist(dev)))

			app = App.find_by_id(app_id)
			ValidationService.raise_validation_error(ValidationService.validate_app_does_not_exist(app))
			ValidationService.raise_validation_error(ValidationService.validate_website_call_and_user_is_app_dev(user, dev, app))

			event = Event.find_by(name: name, app: app_id)
			ValidationService.raise_validation_error(ValidationService.validate_event_does_not_exist(event))

			if period < 0
				period = 0
			elsif period > 3
				period = 3
			end

			# Return the data
			result = event.attributes
			summaries = Array.new

			event.standard_event_summaries.where("period = ? AND time > ? AND time < ?", period, start_timestamp, end_timestamp).each do |summary|
				# Add the summary to the array
				log = {
					time: summary.time,
					total: summary.total
				}

				os = Array.new
				summary.event_summary_os_counts.each do |obj|
					os.push({
						name: obj.name,
						version: obj.version,
						count: obj.count
					})
				end

				browser = Array.new
				summary.event_summary_browser_counts.each do |obj|
					browser.push({
						name: obj.name,
						version: obj.version,
						count: obj.count
					})
				end

				country = Array.new
				summary.event_summary_country_counts.each do |obj|
					country.push({
						country: obj.country,
						count: obj.count
					})
				end

				log["os"] = os
				log["browser"] = browser
				log["country"] = country
				summaries.push(log)
			end

			result["period"] = period
			result["summaries"] = summaries

			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

   def update_event
      jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		event_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(event_id)
			])

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
				ValidationService.raise_validation_error(ValidationService.validate_event_name_too_short(name))
				ValidationService.raise_validation_error(ValidationService.validate_event_name_too_long(name))
				ValidationService.raise_validation_error(ValidationService.validate_event_name_taken(name, event.name, app.id))
			end

			event.name = name
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(event.save))

			result = event.attributes
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
	
	def delete_event
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		event_id = params["id"]
		
		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(event_id)
			])

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
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_app
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		id = params[:id]

		begin
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_jwt_missing(jwt),
				ValidationService.validate_id_missing(id)
			])

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
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_users
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])

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
				hash["last_active"] = user.last_active

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
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_active_users
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		start_timestamp = params["start"] ? DateTime.strptime(params["start"],'%s').beginning_of_day : (Time.now - 1.month).beginning_of_day
		end_timestamp = params["end"] ? DateTime.strptime(params["end"],'%s').beginning_of_day : Time.now.beginning_of_day

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
			ValidationService.raise_validation_error(ValidationService.validate_users_dev_is_dev(user, dev))
			
			days = Array.new
			ActiveUser.where("time >= ? AND time <= ?", start_timestamp, end_timestamp).each do |active_user|
				day = Hash.new
				day["time"] = active_user.time.to_s
				day["count_daily"] = active_user.count_daily
				day["count_monthly"] = active_user.count_monthly
				day["count_yearly"] = active_user.count_yearly
				days.push(day)
			end

			result = Hash.new
			result["days"] = days
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	private
	def user_was_active(user, timeframe)
		return !user.last_active ? false : Time.now - user.last_active < timeframe
	end
end