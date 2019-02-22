class EventSummary < ApplicationRecord
	belongs_to :event
	has_many :event_summary_property_counts, dependent: :destroy
end