class TableObject < ActiveRecord::Base
   belongs_to :table
   has_many :properties, dependent: :destroy
end