class UserNotifier < ApplicationMailer
   default :from => 'no-reply@dav-apps.tech'

   # send a signup email to the user, pass in the user object that contains the user's email address, username and email_confirmation_token
   def send_verification_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "confirm_user/#{@user.id}/#{@user.email_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Verifiy your email address')
   end

   def send_delete_account_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "delete_account/#{@user.id}/#{@user.email_confirmation_token}/#{@user.password_confirmation_token}"

      make_bootstrap_mail(:to => @user.email, :subject => 'Delete your account')
   end
   
   def send_reset_password_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "reset_password/#{@user.password_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Reset your password')
   end
   
   def send_change_email_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "change_email/#{@user.id}/#{@user.email_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.new_email, :subject => 'Confirm your new email adress')
   end
   
   def send_reset_new_email_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "reset_new_email/#{@user.id}"
      
      make_bootstrap_mail(:to => @user.old_email, :subject => 'Your email was changed')
   end
   
   def send_change_password_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "change_password/#{@user.id}/#{@user.password_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Confirm your new password')
   end

   def send_export_data_email(user)
      @user = user
      @link = ENV["BASE_URL"] + "user#archives"

      make_bootstrap_mail(:to => @user.email, :subject => 'The archive of your account is ready')
   end

   def send_failed_payment_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "user#plans"

      make_bootstrap_mail(:to => @user.email, :subject => "Subscription renewal was not possible")
   end
end
