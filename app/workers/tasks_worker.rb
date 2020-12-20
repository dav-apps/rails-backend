class TasksWorker
   include Sidekiq::Worker

   def perform
		update_used_storage_of_users
		update_used_storage_of_users_apps
		update_users_apps
   end

   def get_file_size_of_table_object(obj_id)
		obj = TableObject.find_by_id(obj_id)
		return if obj.nil?
		
		# Get the size property of the table_object
      PropertyDelegate.where(table_object_id: obj.id).each do |prop|
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

   # Tasks
	def update_used_storage_of_users
		UserMigration.all.each do |user|
			used_storage = 0

			TableObjectDelegate.where(user_id: user.id, file: true).each do |obj|
				used_storage += get_file_size_of_table_object(obj.id)
			end

			user.used_storage = used_storage
			user.save
		end
	end

	def update_used_storage_of_users_apps
		UsersAppMigration.all.each do |users_app|
			# Get the table objects of tables of the app and of the user
			used_storage = 0

			TableDelegate.where(app_id: users_app.app_id).each do |table|
				TableObjectDelegate.where(table_id: table.id, user_id: users_app.user_id, file: true).each do |obj|
					used_storage += get_file_size_of_table_object(obj.id)
				end
			end

			users_app.used_storage = used_storage
			users_app.save
		end
	end

	def update_users_apps
		UserMigration.all.each do |user|
			apps = Array.new
			UsersAppDelegate.where(user_id: user.id).each do |users_app|
				app = AppDelegate.find_by(id: users_app.app_id)
				apps.push(app) if !app.nil?
			end

			apps.each do |app|
				# Check if the user still uses the app
				uses_app = false
				TableDelegate.where(app_id: app.id).each do |table|
					if !uses_app
						uses_app = TableObjectDelegate.where(table_id: table.id, user_id: user.id).count > 0
					end
				end

				if !uses_app
					# The user has no table object of the app
					users_app = UsersAppDelegate.find_by(user_id: user.id, app_id: app.id)
					users_app.destroy if !users_app.nil?
				end
			end
		end
	end
end