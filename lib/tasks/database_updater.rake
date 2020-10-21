namespace :database_updater do
	period_hour = 0
	period_day = 1
	period_month = 2
	period_year = 3

  	desc "Update the used_storage field of users"
  	task update_used_storage_of_users: :environment do
		User.all.each do |user|
			used_storage = 0

			user.table_objects.where(file: true).each do |obj|
				used_storage += get_file_size_of_table_object(obj.id)
			end

			user.used_storage = used_storage
			user.save
		end
	end

	desc "Update the used_storage field of users_apps"
  	task update_used_storage_of_users_apps: :environment do
		UsersApp.all.each do |users_app|
			# Get the table objects of tables of the app and of the user
			used_storage = 0

			users_app.app.tables.each do |table|
				table.table_objects.where(user_id: users_app.user_id, file: true).each do |obj|
					used_storage += get_file_size_of_table_object(obj.id)
				end
			end

			users_app.used_storage = used_storage
			users_app.save
		end
	end

	desc "Remove unnecessary users_apps objects"
  	task update_users_apps: :environment do
		User.all.each do |user|
			user.apps.each do |app|
				# Check if the user still uses the app
				uses_app = false
				app.tables.each do |table|
					if !uses_app
						uses_app = table.table_objects.where(user_id: user.id).count > 0
					end
				end

				if !uses_app
					# The user has no table object of the app
					users_app = UsersApp.find_by(user_id: user.id, app_id: app.id)

					if users_app
						users_app.destroy!
					end
				end
			end
		end
	end

	desc "Creates a lot of table objects for testing database performance"
	task generate_test_data: :environment do
		i = 0
		target = 10000

		while i < target
			obj = TableObject.new
			obj.table_id = rand(20)
			obj.user_id = 8
			obj.uuid = SecureRandom.uuid
			obj.save

			number_properties = rand(4) + 1
			j = 0
			
			while j < number_properties
				prop = Property.new
				prop.table_object_id = obj.id
				prop.name = ('a'..'z').to_a.shuffle[0,8].join
				prop.value = ('a'..'z').to_a.shuffle[0,16].join
				prop.save

				j += 1
			end

			i += 1
		end
	end

	desc "Updates all caches by executing each cached endpoint with the saved combination of params"
	task update_caches: :environment do
		Api.all.each do |api|
			api.api_endpoints.where(caching: true).each do |api_endpoint|
				# Get the environment variables of the api
				vars = Hash.new
				vars["env"] = Hash.new
				api.api_env_vars.each do |env_var|
					vars["env"][env_var.name] = UtilsService.convert_env_value(env_var.class_name, env_var.value)
				end

				caches = ApiEndpointRequestCache.where(api_endpoint: api_endpoint)
				caches.each do |cache|
					# Get the params
					cache.api_endpoint_request_cache_params.each do |param|
						vars[param.name] = param.value
					end

					runner = DavExpressionRunner.new
					result = runner.run({
						api: api,
						vars: vars,
						commands: api_endpoint.commands
					})

					if result[:status] == 200 && !result[:file]
						# Update the cache
						cache.response = result[:data].to_json
						cache.save
					end
				end
			end
		end
	end

	desc "Create EventSummaries with the count of the values"
	task create_event_summaries: :environment do
		# Create summaries of event logs
		EventLog.where(processed: [false, nil]).limit(100).each do |log|
			[period_hour, period_day, period_month, period_year].each do |period|
				case period
				when period_day
					time = log.created_at.beginning_of_day
				when period_month
					time = log.created_at.beginning_of_month
				when period_year
					time = log.created_at.beginning_of_year
				else
					time = log.created_at.beginning_of_hour
				end
				
				# Find the appropriate EventSummary or create it
				summary = EventSummary.find_by(event_id: log.event_id, period: period, time: time)
				if !summary
					# Create the EventSummary
					summary = EventSummary.create(event_id: log.event_id, period: period, time: time)
				end
				summary.total += 1
				summary.save

				log.event_log_properties.each do |log_prop|
					sum_prop = summary.event_summary_property_counts.find_by(name: log_prop.name, value: log_prop.value)
					if !sum_prop
						# Create the EventSummaryPropertyCount
						sum_prop = EventSummaryPropertyCount.create(event_summary_id: summary.id, name: log_prop.name, value: log_prop.value)
					end
					
					sum_prop.count += 1
					sum_prop.save
				end
			end

			log.processed = true
			log.save
		end

		# Create summaries of standard event logs
		StandardEventLog.where(processed: false).limit(100).each do |log|
			# Process the event log for each period
			[period_hour, period_day, period_month, period_year].each do |period|
				case period
				when period_day
					time = log.created_at.beginning_of_day
				when period_month
					time = log.created_at.beginning_of_month
				when period_year
					time = log.created_at.beginning_of_year
				else
					time = log.created_at.beginning_of_hour
				end

				# Find the appropriate StandardEventSummary or create it
				summary = StandardEventSummary.find_by(event_id: log.event_id, period: period, time: time)
				if !summary
					# Create the StandardEventSummary
					summary = StandardEventSummary.create(event_id: log.event_id, period: period, time: time)
				end
				summary.total += 1
				summary.save

				# Find or create the count for os
				os_count = EventSummaryOsCount.find_by(standard_event_summary_id: summary.id, name: log.os_name, version: log.os_version)
				if !os_count
					os_count = EventSummaryOsCount.create(standard_event_summary_id: summary.id, name: log.os_name, version: log.os_version)
				end
				os_count.count += 1
				os_count.save

				# Find or create the count for browser
				browser_count = EventSummaryBrowserCount.find_by(standard_event_summary_id: summary.id, name: log.browser_name, version: log.browser_version)
				if !browser_count
					browser_count = EventSummaryBrowserCount.create(standard_event_summary_id: summary.id, name: log.browser_name, version: log.browser_version)
				end
				browser_count.count += 1
				browser_count.save

				# Find or create the count for country
				country_count = EventSummaryCountryCount.find_by(standard_event_summary_id: summary.id, country: log.country)
				if !country_count
					country_count = EventSummaryCountryCount.create(standard_event_summary_id: summary.id, country: log.country)
				end
				country_count.count += 1
				country_count.save
			end

			log.processed = true
			log.save
		end

		# Convert event logs to standard event logs
		EventLog.where(processed: true).limit(500).each do |log|
			new_log = StandardEventLog.new(event_id: log.event_id, created_at: log.created_at)

			# Get the properties of the log
			log.event_log_properties.each do |prop|
				case prop.name
				when "os_name"
					new_log.os_name = prop.value
				when "os_version"
					new_log.os_version = prop.value
				when "browser_name"
					new_log.browser_name = prop.value
				when "browser_version"
					new_log.browser_version = prop.value
				when "country"
					new_log.country = prop.value
				end
			end

			new_log.save

			# Delete the old event log
			log.destroy!
		end
	end

	desc "Get the current active users and create the active user objects in the database"
	task create_active_users: :environment do
		# Create active users for each app
		App.all.each do |app|
			create_active_user(app.id, app.users_apps)
		end

		# Create active user for all users
		create_active_user(-1, User.all)
	end

	def create_active_user(app_id, users)
		# Count the active users of the app
		count_daily = 0
		count_monthly = 0
		count_yearly = 0

		users.each do |user|
			# Check if the user was active
			count_daily += 1 if user_was_active(user.last_active, 1.day)
			count_monthly += 1 if user_was_active(user.last_active, 1.month)
			count_yearly += 1 if user_was_active(user.last_active, 1.year)
		end

		# Create a ActiveUser object for the app for the current day
		if app_id > 0
			ActiveAppUser.create(app_id: app_id, 
								time: Time.now.beginning_of_day,
								count_daily: count_daily,
								count_monthly: count_monthly,
								count_yearly: count_yearly)
		else
			ActiveUser.create(time: Time.now.beginning_of_day,
								count_daily: count_daily,
								count_monthly: count_monthly,
								count_yearly: count_yearly)
		end
	end

	def user_was_active(last_active, timeframe)
		return !last_active ? false : Time.now - last_active < timeframe
	end
	
	def get_file_size_of_table_object(obj_id)
      obj = TableObject.find_by_id(obj_id)

		if !obj
			return
		end
		
      obj.properties.each do |prop| # Get the size property of the table_object
         if prop.name == "size"
            return prop.value.to_i
         end
      end

      # If size property was not saved, get file size directly from Azure
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
      client = Azure::Blob::BlobService.new

      begin
         # Check if the object is a file
         blob = client.get_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{obj.table.app_id}/#{obj.id}")
         return blob[0].properties[:content_length].to_i # The size of the file in bytes
      rescue Exception => e
         puts e
      end

      return 0
   end
end
