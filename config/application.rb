require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Workspace
  	class Application < Rails::Application
    	config.api_only = true
    	# Settings in config/environments/* take precedence over those specified here.
    	# Application configuration should go into files in config/initializers
    	# -- all .rb files in that directory are automatically loaded.

		# Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
		# Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
		# config.time_zone = 'Central Time (US & Canada)'

		# The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
		# config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
		# config.i18n.default_locale = :de

		# Use sidekiq for async jobs
		config.active_job.queue_adapter = :sidekiq

		# Do not swallow errors in after_commit/after_rollback callbacks.
		config.active_record.raise_in_transactional_callbacks = true

		Rails.application.config.middleware.insert_before 0, Rack::Cors do
			allow do
				origins 	ENV['BASE_URL'],
							'localhost:3001',
							'cards-dav.azurewebsites.net',
							'calendo-dav.azurewebsites.net',
							'calendo.dav-apps.tech',
							'blog.dav-apps.tech'
							

				resource '*',
				headers: :any,
          	methods: %i(get post put patch delete options head)
			end
    	end
  	end
end
