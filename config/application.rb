require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "action_controller/railtie"
require "action_mailer/railtie"
require "action_view/railtie"
require "action_cable/engine"
# require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Workspace
  	class Application < Rails::Application
    	# Initialize configuration defaults for originally generated Rails version.
    	config.load_defaults 5.1

		# Settings in config/environments/* take precedence over those specified here.
		# Application configuration should go into files in config/initializers
		# -- all .rb files in that directory are automatically loaded.

		# Only loads a smaller set of middleware suitable for API only apps.
		# Middleware like session, flash, cookies can be added back manually.
		# Skip views, helpers and assets when generating a new resource.
		config.api_only = true

		config.action_cable.allowed_request_origins = [
			"http://localhost:3001",
			"https://calendo.dav-apps.tech",
			"https://calendo-dav.azurewebsites.net",
         "https://calendo-dav-staging.azurewebsites.net",
         "https://pocketlib.dav-apps.tech",
         "https://pocketlib-dav.azurewebsites.net",
         "https://pocketlib-dav-staging.azurewebsites.net",
			nil
		]

    	Rails.application.config.middleware.insert_before 0, Rack::Cors do
			allow do
				origins 	ENV['BASE_URL'],
							'blog.dav-apps.tech',
							'localhost:3001',
							'cards-dav.azurewebsites.net',
							'calendo-dav.azurewebsites.net',
							'calendo.dav-apps.tech',
							'calendo-dav-staging.azurewebsites.net',
							'pocketlib.dav-apps.tech',
         				'pocketlib-dav.azurewebsites.net',
         				'pocketlib-dav-staging.azurewebsites.net'
				
				resource '*',
				headers: :any,
          	methods: %i(get post put patch delete options head)
			end
		end
  	end
end
