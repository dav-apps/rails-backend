class UserNotifierPreview < ActionMailer::Preview
	def verification_email
		UserNotifier.send_verification_email(User.first)
	end

	def delete_account_email
		UserNotifier.send_delete_account_email(User.first)
	end

	def reset_password_email
		UserNotifier.send_reset_password_email(User.first)
	end

   def change_email_email
     UserNotifier.send_change_email_email(User.first)
	end
	
	def reset_new_email_email
		UserNotifier.send_reset_new_email_email(User.first)
	end

	def change_password_email
		UserNotifier.send_change_password_email(User.first)
	end

	def export_data_email
		UserNotifier.send_export_data_email(User.first)
	end

	def failed_payment_email
		UserNotifier.send_failed_payment_email(User.first)
	end
end