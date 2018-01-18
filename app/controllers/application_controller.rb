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
end
