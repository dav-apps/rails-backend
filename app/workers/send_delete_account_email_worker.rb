class SendDeleteAccountEmailWorker
  include Sidekiq::Worker

  def perform(user)
    UserNotifier.send_delete_account_email(user).deliver_later
  end
end
