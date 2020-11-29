source 'https://rubygems.org'

ruby '2.6.6'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '5.2.4.4'
# Use SCSS for stylesheets
gem 'sassc-rails'

gem 'rack-protection',  '~> 1.5.5'

gem 'bcrypt'
gem 'sendgrid-ruby'
gem 'jwt'

gem 'tiny_tds', '~> 1.3'
gem 'activerecord-sqlserver-adapter', '5.2.0'

gem 'rack-cors', :require => 'rack/cors'

# Azure File Storage
gem 'azure'
gem 'azure-contrib', git: 'https://github.com/Dav2070/azure-contrib.git'

# MiniMagick for image processing
gem "mini_magick"

# Use Puma as the app server
gem 'puma'

# mysql for development database
gem 'mysql2', '~> 0.5.2'

# Sidekiq for async workers
gem 'sidekiq'

# Stripe for payments
gem 'stripe'
gem 'stripe_event'
gem 'stripe-ruby-mock', '~> 3.0.1', :require => 'stripe_mock'

# Bootstrap emails
gem 'bootstrap-email'

# IP location
gem 'IPinfo', git: 'https://github.com/ipinfo/ruby'

# Web Push
gem 'webpush'

# S-Expression parser
gem 'sexpistol', git: 'https://github.com/dav-apps/sexpistol'

# Blurhash
gem 'blurhash'
gem 'rmagick'

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

  gem 'listen'
end