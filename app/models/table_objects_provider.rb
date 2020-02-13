class TableObjectsProvider < ApplicationRecord
	belongs_to :table_object
	belongs_to :provider
end