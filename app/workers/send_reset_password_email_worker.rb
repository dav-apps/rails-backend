class SendResetPasswordEmailWorker
  include Sidekiq::Worker

  def perform(user)
    UserNotifier.send_reset_password_email(user).deliver_later
  end
end
