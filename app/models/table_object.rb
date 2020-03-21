class TableObject < ApplicationRecord
   after_destroy :delete_blob

   belongs_to :table
	belongs_to :user
   has_many :properties, dependent: :destroy
   validates :uuid, presence: true
   has_many :table_objects_access_token
	has_many :access_tokens, through: :table_objects_access_token
	has_many :table_objects_provider
	has_many :providers, through: :table_objects_provider
	has_many :table_object_user_access, dependent: :destroy
	has_many :table_object_collections, dependent: :destroy
	has_many :collections, through: :table_object_collections
	has_many :purchases

   private
   def delete_blob
      begin
         BlobOperationsService.delete_blob(self.table.app.id, self.id)
      rescue => e
      end
   end
end