class Archive < ActiveRecord::Base
   after_destroy :delete_blob

   belongs_to :user

   private
   def delete_blob
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_ARCHIVES_CONTAINER_NAME'], "dav-export-#{self.id}.zip")
      rescue Exception => e
         puts e
      end
   end
end