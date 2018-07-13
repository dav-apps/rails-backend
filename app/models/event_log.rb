class EventLog < ActiveRecord::Base
   belongs_to :event
   has_many :event_log_properties, dependent: :destroy
end