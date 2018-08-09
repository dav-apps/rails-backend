class ArchivePart < ApplicationRecord
	before_destroy :delete_blob

	belongs_to :archive
	
	private
   def delete_blob
      BlobOperationsService.delete_archive(self.name)
   end
end