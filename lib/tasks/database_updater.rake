namespace :database_updater do
  	desc "Update the used_storage field of user"
  	task update_used_storage: :environment do
		User.all.each do |user|
			used_storage = 0

			user.table_objects.where(file: true).each do |obj|
				used_storage += get_file_size_of_table_object(obj.id)
			end

			user.used_storage = used_storage
			user.save
		end
	end

	desc "Update the used_storage field of user"
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