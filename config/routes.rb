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
  get 'user/change_email', to: 'users#change_email'
  get 'user/confirm_new_email', to: 'users#confirm_new_email'
  get 'user/reset_new_email', to: 'users#reset_new_email'
  get 'user/change_password', to: 'users#change_password'
  get 'user/confirm_new_password', to: 'users#confirm_new_password'
  get 'user/set_avatar_file_extension', to: 'users#set_avatar_file_extension'
  
  # Cards routes
  get 'cards/get_all_decks_and_cards', to: 'cards#get_all_decks_and_cards'
  get 'cards/create_deck', to: 'cards#create_deck'
end
