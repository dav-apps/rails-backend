class Dev < ActiveRecord::Base
   belongs_to :user
   has_many :apps, dependent: :destroy
end