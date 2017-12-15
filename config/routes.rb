Rails.application.routes.draw do
  
  # User routes
  match '/v1/users/login', to: 'users#login', via: 'get'
  match '/v1/users/signup', to: 'users#signup', via: 'post'
  match '/v1/users/:id', to: 'users#get_user', via: 'get'
  match '/v1/users', to: 'users#update_user', via: 'put'
  match '/v1/users', to: 'users#delete_user', via: 'delete'
  
  match '/v1/users/send_verification_email', to: 'users#send_verification_email', via: 'post'
  match '/v1/users/send_reset_password_email', to: 'users#send_reset_password_email', via: 'post'
  match '/v1/users/:id/save_new_password/:password_confirmation_token', to: 'users#save_new_password', via: 'post'
  match '/v1/users/:id/save_new_email/:email_confirmation_token', to: 'users#save_new_email', via: 'post'
  match '/v1/users/:id/reset_new_email', to: 'users#reset_new_email', via: 'post'
  match '/v1/users/:id/confirm', to: 'users#confirm_user', via: 'post'
  
  # Dev routes
  match '/v1/devs/dev', to: 'devs#create_dev', via: 'post'
  match '/v1/devs/dev', to: 'devs#get_dev', via: 'get'
  match '/v1/devs/dev/:api_key', to: 'devs#get_dev_by_api_key', via: 'get'
  match '/v1/devs/dev', to: 'devs#delete_dev', via: 'delete'
  match '/v1/devs/generate_new_keys', to: 'devs#generate_new_keys', via: 'post'
  
  # Apps routes
  match '/v1/apps/object', to: 'apps#create_object', via: 'post'
  match '/v1/apps/object/:id', to: 'apps#get_object', via: 'get'
  match '/v1/apps/object/:id', to: 'apps#update_object', via: 'put'
  match '/v1/apps/object/:id', to: 'apps#delete_object', via: 'delete'
  
  match '/v1/apps/table', to: 'apps#create_table', via: 'post'
  match '/v1/apps/table', to: 'apps#get_table', via: 'get'
  match '/v1/apps/table/:id', to: 'apps#update_table', via: 'put'
  match '/v1/apps/table/:id', to: 'apps#delete_table', via: 'delete'
  
  match '/v1/apps/app', to: 'apps#create_app', via: 'post'
  match '/v1/apps/app/:id', to: 'apps#get_app', via: 'get'
  match '/v1/apps/app/:id', to: 'apps#update_app', via: 'put'
  match '/v1/apps/app/:id', to: 'apps#delete_app', via: 'delete'
  
  match '/v1/apps/access_token', to: 'apps#create_access_token', via: 'post'
  
  # Analytics routes
  match '/v1/analytics/event', to: 'analytics#create_event_log', via: 'post'
  match '/v1/analytics/event/:id', to: 'analytics#get_event', via: 'get'
  match '/v1/analytics/event', to: 'analytics#get_event_by_name', via: 'get'
  match '/v1/analytics/event/:id', to: 'analytics#update_event', via: 'put'
  match '/v1/analytics/event/:id', to: 'analytics#delete_event', via: 'delete'
end
