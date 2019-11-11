class StandardEventSummary < ApplicationRecord
	belongs_to :event
	has_many :event_summary_os_counts, dependent: :destroy
	has_many :event_summary_browser_counts, dependent: :destroy
	has_many :event_summary_country_counts, dependent: :destroy
end