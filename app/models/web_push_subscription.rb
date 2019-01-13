class WebPushSubscription < ApplicationRecord
	validates :uuid, presence: true
	belongs_to :user
end