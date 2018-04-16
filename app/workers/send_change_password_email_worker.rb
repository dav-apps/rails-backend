class SendChangePasswordEmailWorker
  	include Sidekiq::Worker

  	def perform(user)
    	UserNotifier.send_change_password_email(user).deliver_later
  	end
end
