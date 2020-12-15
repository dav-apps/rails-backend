class App < ApplicationRecord
   belongs_to :dev
   has_many :tables
	has_many :events
	has_many :exception_events
   has_many :users_apps
   has_many :users, through: :users_apps
   has_many :notifications
   has_many :active_app_users
	has_many :sessions
	has_many :apis
end