class TableObject < ActiveRecord::Base
   belongs_to :table
   belongs_to :user
   has_many :properties, dependent: :destroy
   has_many :object_access_tokens, dependent: :destroy
end