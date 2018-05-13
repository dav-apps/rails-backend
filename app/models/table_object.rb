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
      begin
         BlobOperationsService.delete_blob(self.table.app.id, self.id)
      rescue => e
      end
   end
end