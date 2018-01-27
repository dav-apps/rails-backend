class TableObject < ActiveRecord::Base
   after_destroy :delete_blob

   belongs_to :table
   belongs_to :user
   has_many :properties, dependent: :destroy
   has_many :object_access_tokens, dependent: :destroy
   validates :uuid, presence: true

   private
   def delete_blob
      Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
      Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]

      client = Azure::Blob::BlobService.new
      begin
         client.delete_blob(ENV['AZURE_FILES_CONTAINER_NAME'], "#{self.table.app.id}/#{self.id}")
      rescue Exception => e
         
      end
   end
end