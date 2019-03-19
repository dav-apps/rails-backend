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

	desc "Create EventSummaries with the count of the values"
	task create_event_summaries: :environment do
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
	end

	desc "Get the current active users and create the active user objects in the database"
	task create_active_users: :environment do
		
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
