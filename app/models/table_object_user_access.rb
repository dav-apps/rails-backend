class TableObjectUserAccess < ApplicationRecord
	belongs_to :table_object
	belongs_to :user
end