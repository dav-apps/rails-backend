class App < ActiveRecord::Base
   belongs_to :dev
   has_many :tables, dependent: :destroy
   has_many :events, dependent: :destroy
end