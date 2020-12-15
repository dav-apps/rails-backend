class Table < ApplicationRecord
   belongs_to :app
	has_many :table_objects
	has_many :collections
	has_many :property_types
end