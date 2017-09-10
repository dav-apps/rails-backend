class App < ActiveRecord::Base
   belongs_to :dev
   # has_many :tables
   has_many :devs
end