class TableObjectsAccessToken < ApplicationRecord
   belongs_to :table_object
   belongs_to :access_token
end