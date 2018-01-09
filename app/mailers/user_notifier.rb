class UserNotifier < ApplicationMailer
   default :from => 'no-reply@dav-apps.tech'

   # send a signup email to the user, pass in the user object that contains the user's email address, username and email_confirmation_token
   def send_verification_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "confirm_user/#{@user.id}/#{@user.email_confirmation_token}"
      
      mail(:to => @user.email,
      :subject => 'Welcome to dav!')
   end
   
   def send_reset_password_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "reset_password/#{@user.password_confirmation_token}"
      
      mail(:to => @user.email,
      :subject => 'Reset your dav password')
   end
   
   def send_change_email_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "change_email/#{@user.id}/#{@user.email_confirmation_token}"
      
      mail(:to => @user.new_email,
      :subject => 'Confirm your new dav email')
   end
   
   def send_reset_new_email_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "reset_new_email/#{@user.id}"
      
      mail(:to => @user.old_email,
      :subject => 'Your dav email was changed')
   end
   
   def send_change_password_email(user)
      @user = user
      @link = ENV['BASE_URL'] + "change_password/#{@user.id}/#{@user.password_confirmation_token}"
      
      mail(:to => @user.email,
      :subject => 'Confirm your new dav password')
   end
end
