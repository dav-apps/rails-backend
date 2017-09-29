Rails.application.routes.draw do
  
  # Authentication routes
  # get 'user/login', to: 'users#login'
  # get 'user/signup', to: 'users#signup'
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
  get 'cards/update_deck', to: 'cards#update_deck'
  get 'cards/delete_deck', to: 'cards#delete_deck'
  get 'cards/create_card', to: 'cards#create_card'
  get 'cards/update_card', to: 'cards#update_card'
  get 'cards/delete_card', to: 'cards#delete_card'
  
  # Analytics routes
  # post '/v1/analytics/event', to: 'analytics#create'
  match '/v1/analytics/event', to: 'analytics#create', via: 'post'
  
  # User routes
  match '/v1/users/login', to: 'users#login', via: 'get'
  match '/v1/users/signup', to: 'users#signup', via: 'post'
  match '/v1/users/:id', to: 'users#update_user', via: 'put'
  match '/v1/users/:id', to: 'users#delete_user', via: 'delete'
  
  # Apps routes
  match '/v1/apps/object', to: 'apps#create_object', via: 'post'
  match '/v1/apps/object', to: 'apps#get_object', via: 'get'
  match '/v1/apps/object', to: 'apps#update_object', via: 'put'
  match '/v1/apps/object', to: 'apps#delete_object', via: 'delete'
  
  match '/v1/apps/table', to: 'apps#create_table', via: 'post'
  match '/v1/apps/table', to: 'apps#get_table', via: 'get'
  match '/v1/apps/table', to: 'apps#update_table', via: 'put'
  match '/v1/apps/table', to: 'apps#delete_table', via: 'delete'
  
  match '/v1/apps/app', to: 'apps#create_app', via: 'post'
  match '/v1/apps/app', to: 'apps#get_app', via: 'get'
  match '/v1/apps/app', to: 'apps#update_app', via: 'put'
  match '/v1/apps/app', to: 'apps#delete_app', via: 'delete'
end
