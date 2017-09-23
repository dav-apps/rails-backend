class Table < ActiveRecord::Base
   belongs_to :app
   has_many :table_objects, dependent: :destroy
end