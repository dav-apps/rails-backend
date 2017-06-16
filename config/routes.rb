Rails.application.routes.draw do
  
  # Authentication routes
  get 'user/login', to: 'users#login'
  get 'user/signup', to: 'users#signup'
  get 'user/set_username', to: 'users#set_username'
  get 'user/confirm_user', to: 'users#confirm_user'
  get 'user/send_verification_email', to: 'users#send_verification_email'
  get 'user/send_password_reset_email', to: 'users#send_password_reset_email'
  get 'user/check_password_confirmation_token', to: 'users#check_password_confirmation_token'
  get 'user/save_new_password', to: 'users#save_new_password'
end
