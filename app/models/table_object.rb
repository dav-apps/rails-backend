class TableObject < ActiveRecord::Base
   after_destroy :delete_blob

   belongs_to :table
   belongs_to :user
   has_many :properties, dependent: :destroy
   validates :uuid, presence: true
   has_many :table_objects_access_token
   has_many :access_tokens, through: :table_objects_access_token

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