class Notification < ApplicationRecord
	validates :uuid, presence: true
	belongs_to :app
	belongs_to :user
	has_many :notification_properties
end