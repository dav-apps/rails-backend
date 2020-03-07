class Collection < ApplicationRecord
	belongs_to :table
	has_many :table_object_collections, dependent: :destroy
	has_many :table_objects, through: :table_object_collections
end