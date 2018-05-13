class Archive < ActiveRecord::Base
   after_destroy :delete_blob

   belongs_to :user

   private
   def delete_blob
      BlobOperationsService.delete_archive(self.id)
   end
end