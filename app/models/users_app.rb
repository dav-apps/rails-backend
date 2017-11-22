class UsersApp < ActiveRecord::Base
   belongs_to :user
   belongs_to :app
end