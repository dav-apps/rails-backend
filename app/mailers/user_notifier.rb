class UserNotifier < ApplicationMailer
   default :from => 'no-reply@dav-apps.tech'

   def send_verification_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=confirm_user&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Verifiy your email address')
   end

   def send_delete_account_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=delete_user&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}&password_confirmation_token=#{@user.password_confirmation_token}"

      make_bootstrap_mail(:to => @user.email, :subject => 'Delete your account')
	end
	
	def send_remove_app_email(user, app)
		@user = user
		@app = app
		@link = "#{ENV['BASE_URL']}/email_link?type=remove_app&app_id=#{@app.id}&user_id=#{@user.id}&password_confirmation_token=#{@user.password_confirmation_token}"

		make_bootstrap_mail(:to => @user.email, :subject => "Remove #{@app.name} from your account")
	end
   
   def send_password_reset_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/reset_password?user_id=#{@user.id}&password_confirmation_token=#{@user.password_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Reset your password')
   end
   
   def send_change_email_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=change_email&user_id=#{@user.id}&email_confirmation_token=#{@user.email_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.new_email, :subject => 'Confirm your new email adress')
   end
   
   def send_reset_new_email_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=reset_new_email&user_id=#{@user.id}"
		
      make_bootstrap_mail(:to => @user.old_email, :subject => 'Your email was changed')
   end
   
   def send_change_password_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/email_link?type=change_password&user_id=#{@user.id}&password_confirmation_token=#{@user.password_confirmation_token}"
      
      make_bootstrap_mail(:to => @user.email, :subject => 'Confirm your new password')
   end

   def send_failed_payment_email(user)
      @user = user
		@link = "#{ENV['BASE_URL']}/user#plans"

      make_bootstrap_mail(:to => @user.email, :subject => "Subscription renewal was not possible")
   end
end
