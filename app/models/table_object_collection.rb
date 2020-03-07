class TableObjectCollection < ApplicationRecord
	belongs_to :table_object
	belongs_to :collection
end