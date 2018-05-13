class BlobOperationsService
	def self.download_blob(app_id, object_id, object_ext, path)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      begin
         full_path = path + object_id.to_s + "." + object_ext
         filename = "#{app_id}/#{object_id}"
         
         client = Azure::Blob::BlobService.new
         blob, content = client.get_blob(ENV['AZURE_FILES_CONTAINER_NAME'], filename)
         File.open(full_path,"wb") {|f| f.write(content)}
      rescue Exception => e
         
      end
	end
	
	def self.upload_blob(app_id, object_id, blob)
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
	
	def self.delete_blob(app_id, object_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{app_id}/#{object_id}")
      rescue Exception => e
         
      end
	end
	
	def self.upload_archive(archive_path)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      file = File.open(archive_path, "rb")
      contents = file.read
      filename = File.basename(archive_path)

      client = Azure::Blob::BlobService.new
      begin
         blob = client.create_block_blob(ENV["AZURE_ARCHIVES_CONTAINER_NAME"], filename, contents)
      rescue Exception => e
         
      end
	end
	
	def self.download_archive(archive_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      begin
         archive = Archive.find_by_id(archive_id)
         client = Azure::Blob::BlobService.new
         blob = client.get_blob(ENV['AZURE_ARCHIVES_CONTAINER_NAME'], "dav-export-#{archive.id}.zip")
         return blob
      rescue Exception => e
         
      end
   end

   def self.delete_archive(archive_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         archive = Archive.find_by_id(archive_id)
         client.delete_blob(ENV['AZURE_ARCHIVES_CONTAINER_NAME'], archive.name)
      rescue Exception => e
         
      end
	end
	
	def self.get_users_avatar(user_id)
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

   def self.delete_avatar(user_id)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_AVATAR_CONTAINER_NAME'], user_id.to_s + ".png")
      rescue Exception => e
         
      end
   end
end