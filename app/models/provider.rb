class Provider < ApplicationRecord
	belongs_to :user
	has_many :table_objects_provider
	has_many :table_objects, through: :table_objects_provider
end