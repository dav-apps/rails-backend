namespace :tasks do
	task create_user_snapshots: :environment do
		# Call the appropriate endpoint on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/create_user_snapshots", {}, {})
	end

	task send_notifications: :environment do
		# Call the appropriate endpoint on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/send_notifications", {}, {})
	end

	task delete_sessions: :environment do
		# Call the appropriate endpoint on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/delete_sessions", {}, {})
	end

	task delete_purchases: :environment do
		# Call the appropriate endpoint on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/delete_purchases", {}, {})
	end

	task update_redis_caches: :environment do
		# Call the appropriate endpoint on the new backend
		RestClient.put("https://dav-backend-tfpik.ondigitalocean.app/v1/tasks/update_redis_caches", {}, {})
	end
end