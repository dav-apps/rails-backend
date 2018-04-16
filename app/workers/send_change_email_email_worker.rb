class SendChangeEmailEmailWorker
  	include Sidekiq::Worker

  	def perform(user)
    	UserNotifier.send_change_email_email(user).deliver_later
  	end
end
