class AccessToken < ActiveRecord::Base
   has_many :table_objects_access_token, dependent: :destroy
   has_many :table_objects, through: :table_objects_access_token
end