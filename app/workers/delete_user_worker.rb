class DeleteUserWorker
	include Sidekiq::Worker

	def perform(user_id)
		user = UserDelegate.find_by(id: user_id)
		user.destroy if !user.nil?
	end
end