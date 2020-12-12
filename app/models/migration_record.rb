class MigrationRecord < ActiveRecord::Base
	self.abstract_class = true
	
	connects_to database: { writing: :migration, reading: :migration }
end