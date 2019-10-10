class DeleteUserWorker
	include Sidekiq::Worker

	def perform(user_id)
		user = User.find_by_id(user_id)

		if user
			user.destroy!
		end
	end
end