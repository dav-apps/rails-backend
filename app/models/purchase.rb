class Purchase < ApplicationRecord
	belongs_to :user
	belongs_to :table_object
end