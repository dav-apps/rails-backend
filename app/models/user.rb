class User < ApplicationRecord
	before_save { self.email = email.downcase }
	after_destroy :delete_avatar

	validates :username, presence: true, uniqueness: {case_sensitive: false},
					length: {minimum: 2, maximum: 25}
	VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-.]+\.[a-z]+\z/i
	validates :email, presence: true, length: {maximum: 105},
				uniqueness: {case_sensitive: false},
				format: {with: VALID_EMAIL_REGEX}
	has_secure_password
   
	has_one :dev, dependent: :destroy
	has_many :table_objects, dependent: :destroy
	has_many :users_apps, dependent: :destroy
	has_many :apps, through: :users_apps
	has_many :archives, dependent: :destroy
	has_many :notifications, dependent: :destroy
   has_many :web_push_subscriptions, dependent: :destroy
	has_many :sessions, dependent: :destroy
	has_one :provider, dependent: :destroy
	has_many :table_object_user_access, dependent: :destroy
	has_many :purchases

	private
	def delete_avatar
		BlobOperationsService.delete_avatar(self.id)
	end
end