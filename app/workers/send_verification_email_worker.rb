class SendVerificationEmailWorker
  	include Sidekiq::Worker

  	def perform(user)
    	UserNotifier.send_verification_email(user).deliver_later
  	end
end
