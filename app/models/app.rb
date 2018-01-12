class App < ActiveRecord::Base
   belongs_to :dev
   has_many :tables, dependent: :destroy
   has_many :events, dependent: :destroy
   has_many :users_apps, dependent: :destroy
   has_many :users, through: :users_apps
end