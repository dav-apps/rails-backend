source 'https://rubygems.org'

ruby '2.5.1'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.1.6'
# Use SCSS for stylesheets
gem 'sassc-rails'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc
gem 'rack-protection',  '~> 1.5.5'

gem 'bcrypt'
gem 'sendgrid-ruby'
gem 'jwt'

gem 'tiny_tds', '~> 1.3'
gem 'activerecord-sqlserver-adapter', '5.1.6'

gem 'rack-cors', :require => 'rack/cors'

# Azure File Storage
gem 'azure'

# MiniMagick for image processing
gem "mini_magick"

# Use Puma as the app server
gem 'puma'

# mysql for development database
gem 'mysql2', '~> 0.5.2'

# Sidekiq for async workers
gem 'sidekiq'

# Rubyzip for packaging zip files
gem 'rubyzip'

# Stripe for payments
gem 'stripe'
gem 'stripe_event'
gem 'stripe-ruby-mock', '~> 2.5.3', :require => 'stripe_mock'

# Bootstrap emails
gem 'bootstrap-email'

# IP location
gem 'ipinfo_io', github: "ipinfo/ruby"

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'
  gem 'dotenv-rails'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  
  gem 'capistrano',         require: false
  gem 'capistrano-rvm',     require: false
  gem 'capistrano-rails',   require: false
  gem 'capistrano-bundler', require: false
  gem 'capistrano3-puma',   require: false

  gem 'listen'
end