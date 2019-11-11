class Event < ApplicationRecord
   belongs_to :app
   has_many :event_logs, dependent: :destroy
	has_many :event_summaries, dependent: :destroy
	has_many :standard_event_logs, dependent: :destroy
	has_many :standard_event_summaries, dependent: :destroy
end