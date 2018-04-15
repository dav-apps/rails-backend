class RemoveAppWorker
  	include Sidekiq::Worker

	def perform(user_id, app_id)
    	# Delete all user data associated with the app
		 TableObject.where(user_id: user_id).each do |obj|
			if obj.table.app_id == app_id
				obj.properties.each do |property|
					property.destroy!
				end
				obj.destroy!
			end
		end
  	end
end
