class SendResetNewEmailEmailWorker
  	include Sidekiq::Worker

  	def perform(user)
    	UserNotifier.send_reset_new_email_email(user).deliver_later
  	end
end
