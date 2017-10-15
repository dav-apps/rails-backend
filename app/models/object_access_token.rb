class ObjectAccessToken < ActiveRecord::Base
   enum visibility: [ :privat, :protected, :public ]
   belongs_to :table_object
end