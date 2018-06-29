namespace :garbage_collector do
  	desc "Delete the archives that are more than one month old"
  	task remove_archives: :environment do
		Archive.all.each do |archive|
			if Time.now - archive.created_at > 1.month
				# Delete the archive
				archive.destroy!
			end
		end
  	end
end
