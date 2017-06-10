class UserNotifier < ApplicationMailer
   default :from => 'no-reply@dav-apps.tech'

   # send a signup email to the user, pass in the user object that contains the user's email address, username and email_confirmation_token
   def send_signup_email(user)
      @user = user
      mail(:to => @user.email,
      :subject => 'Hello ' + @user.username + '!')
   end
end
