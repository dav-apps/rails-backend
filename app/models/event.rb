class Event < ApplicationRecord
   belongs_to :app
   has_many :event_logs, dependent: :destroy
end