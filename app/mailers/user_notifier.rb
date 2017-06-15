class UserNotifier < ApplicationMailer
   default :from => 'no-reply@dav-apps.tech'

   # send a signup email to the user, pass in the user object that contains the user's email address, username and email_confirmation_token
   def send_signup_email(user)
      @user = user
      @activationLink = ENV['BASE_URL'] + "confirmation/" + @user.id.to_s + "/" + @user.email_confirmation_token
      
      mail(:to => @user.email,
      :subject => 'Welcome to dav!')
   end
end
