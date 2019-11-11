class CreateEventSummaryCountryCount < ActiveRecord::Migration[5.2]
  def change
	 create_table :event_summary_country_counts do |t|
		t.integer :standard_event_summary_id
		t.string :country
		t.integer :count, default: 0
    end
  end
end
