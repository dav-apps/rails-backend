class User < ApplicationRecord
	before_save { self.email = email.downcase }

	validates :username, presence: true, length: {minimum: 2, maximum: 25}
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 105},
				uniqueness: {case_sensitive: false},
				format: {with: VALID_EMAIL_REGEX}
	has_secure_password
   
	has_one :dev
	has_many :table_objects
	has_many :users_apps
	has_many :apps, through: :users_apps
	has_many :notifications
   has_many :web_push_subscriptions
	has_many :sessions
	has_one :provider
	has_many :table_object_user_access
	has_many :purchases
end