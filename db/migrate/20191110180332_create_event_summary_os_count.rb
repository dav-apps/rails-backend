class CreateEventSummaryOsCount < ActiveRecord::Migration[5.2]
  def change
	 create_table :event_summary_os_counts do |t|
		t.integer :standard_event_summary_id
		t.string :name
		t.string :version
		t.integer :count, default: 0
    end
  end
end
