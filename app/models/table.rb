class Table < ApplicationRecord
   belongs_to :app
	has_many :table_objects, dependent: :destroy
	has_many :collections, dependent: :destroy
	has_many :property_types, dependent: :destroy
end