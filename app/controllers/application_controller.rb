class ApplicationController < ActionController::API
   
   def check_authorization(api_key, signature)
      dev = Dev.find_by(api_key: api_key)
      
      if !dev
         false
      else
         if api_key == dev.api_key
            
            new_sig = Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid))
            
            if new_sig == signature
               true
            else
               false
            end
         else
            false
         end
      end
   end

   def validate_url(url)
      url =~ /\A#{URI::regexp}\z/
   end

   def get_file_size(file)
      size = 0

      if file.class == StringIO
         size = file.size
      else
         size = File.size(file)
      end

      return size
   end

   def upload_blob(app_id, object_id, blob)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      # Read the file and save it in files container
      if blob.class == StringIO
         file = blob
      else
         file = File.open(blob, "rb")
      end
      contents = file.read

      filename = "#{app_id}/#{object_id}"

      client = Azure::Blob::BlobService.new
      blob = client.create_block_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename, contents)
   end

   def download_blob(app_id, object_id, object_ext, path)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      begin
         full_path = path + object_id.to_s + "." + object_ext
         filename = "#{app_id}/#{object_id}"
         
         client = Azure::Blob::BlobService.new
         blob, content = client.get_blob(ENV['AZURE_FILES_CONTAINER_NAME'], filename)
         File.open(full_path,"wb") {|f| f.write(content)}
      rescue Exception => e
         puts e
      end
   end

   def delete_blob(app_id, object_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{app_id}/#{object_id}")
      rescue Exception => e
         
      end
   end

   def get_users_avatar(user_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
      avatar = Hash.new

      client = Azure::Blob::BlobService.new
      begin
         blob = client.get_blob(ENV['AZURE_AVATAR_CONTAINER_NAME'], user_id.to_s + ".png")
         avatar['url'] = ENV['AZURE_AVATAR_CONTAINER_URL'] + user_id.to_s + ".png"
         etag = blob[0].properties[:etag]
         avatar['etag'] = etag[1...etag.size-1]
      rescue Exception => e
         # Get the blob of the default avatar
         default_blob = client.get_blob(ENV['AZURE_AVATAR_CONTAINER_NAME'], "default.png")
         avatar['url'] = ENV['AZURE_AVATAR_CONTAINER_URL'] + "default.png"
         etag = default_blob[0].properties[:etag]
         avatar['etag'] = etag[1...etag.size-1]
      end
      return avatar
   end

   def delete_avatar(user_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_AVATAR_CONTAINER_NAME'], user_id.to_s + ".png")
      rescue Exception => e
         
      end
   end

   def get_used_storage_by_app(app_id, user_id)
      size = 0
      app = App.find_by_id(app_id)

      if app
         app.tables.each do |table|
            table.table_objects.where(user_id: user_id, file: true).each do |obj|
               size += get_file_size_of_table_object(obj.id)
            end
         end
      end
      
      return size
   end

   def get_file_size_of_table_object(obj_id)
      obj = TableObject.find_by_id(obj_id)

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

   def get_used_storage_of_user(user_id)
      size = 0

      User.find_by_id(user_id).table_objects.where(file: true).each do |obj|
         size += get_file_size_of_table_object(obj.id)
      end

      return size
   end

   def get_total_storage_of_user(user_id)
      storage_on_free_plan = 5000000000 # 5 GB
		storage_on_plus_plan = 50000000000 # 50 GB

      user = User.find_by_id(user_id)
      if user
         if user.plan == 1 # User is on Plus plan
            return storage_on_plus_plan
         else
            return storage_on_free_plan
         end
      end
   end
end
