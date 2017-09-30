Rails.application.routes.draw do
  
  # Cards routes
  get 'cards/get_all_decks_and_cards', to: 'cards#get_all_decks_and_cards'
  get 'cards/create_deck', to: 'cards#create_deck'
  get 'cards/update_deck', to: 'cards#update_deck'
  get 'cards/delete_deck', to: 'cards#delete_deck'
  get 'cards/create_card', to: 'cards#create_card'
  get 'cards/update_card', to: 'cards#update_card'
  get 'cards/delete_card', to: 'cards#delete_card'
  
  # User routes
  match '/v1/users/login', to: 'users#login', via: 'get'
  match '/v1/users/signup', to: 'users#signup', via: 'post'
  match '/v1/users/:id', to: 'users#get_user', via: 'get'
  match '/v1/users/:id', to: 'users#update_user', via: 'put'
  match '/v1/users/:id', to: 'users#delete_user', via: 'delete'
  
  match '/v1/users/send_password_reset_email', to: 'users#send_password_reset_email', via: 'post'
  match '/v1/users/send_verification_email', to: 'users#send_verification_email', via: 'post'
  match '/v1/users/:id/save_new_password/:password_confirmation_token', to: 'users#save_new_password', via: 'post'
  match '/v1/users/:id/save_new_email/:email_confirmation_token', to: 'users#save_new_email', via: 'post'
  
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
  
  # Analytics routes
  match '/v1/analytics/event', to: 'analytics#create', via: 'post'
end
