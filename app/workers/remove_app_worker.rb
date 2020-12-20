class RemoveAppWorker
  	include Sidekiq::Worker

	def perform(user_id, app_id)
    	# Delete all user data associated with the app
		 TableObjectDelegate.where(user_id: user_id).each do |obj|
			table = TableDelegate.find_by(id: obj.table_id)
			next if table.nil?

			if table.app_id == app_id
				obj.destroy
			end
		end
  	end
end
