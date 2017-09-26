class TableObject < ActiveRecord::Base
   belongs_to :table
   belongs_to :user
   has_many :properties, dependent: :destroy
end