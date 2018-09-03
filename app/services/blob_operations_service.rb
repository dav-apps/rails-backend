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

      filename = File.basename(archive_path)

		client = Azure::Blob::BlobService.new
      begin
			client.create_block_blob(ENV["AZURE_ARCHIVES_CONTAINER_NAME"], filename, archive_path, chunking: true)
      rescue Exception => e
         puts e
      end
	end
	
	def self.download_archive(archive_name)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      begin
         client = Azure::Blob::BlobService.new
         client.get_blob(ENV['AZURE_ARCHIVES_CONTAINER_NAME'], archive_name)
      rescue Exception => e
         puts e
      end
	end

   def self.delete_archive(archive_name)
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_ARCHIVES_CONTAINER_NAME'], archive_name)
      rescue Exception => e
         
      end
	end

	def self.get_avatar_information(user_id)
		Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
		Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
		
		client = Azure::Blob::BlobService.new
		blobs = client.list_blobs(ENV['AZURE_AVATAR_CONTAINER_NAME'])

		blob = nil
		default_blob = nil

		blobs.each do |b|
			name = b.name.split('.').first
			if name == user_id.to_s
				blob = b
			elsif name == "default"
				default_blob = b
			end
		end

		# return [name, etag]
		return blob ? [ENV['AZURE_AVATAR_CONTAINER_URL'] + blob.name, blob.properties[:etag]] : [ENV['AZURE_AVATAR_CONTAINER_URL'] + default_blob.name, default_blob.properties[:etag]]
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