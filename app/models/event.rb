class Event < ActiveRecord::Base
   belongs_to :app
   has_many :event_logs
end