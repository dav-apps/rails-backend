class Archive < ApplicationRecord
   before_destroy :delete_blob

   belongs_to :user
   has_many :archive_parts, dependent: :destroy

   private
   def delete_blob
      BlobOperationsService.delete_archive(self.name)
   end
end