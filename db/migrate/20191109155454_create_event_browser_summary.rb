class CreateEventBrowserSummary < ActiveRecord::Migration[5.2]
  def change
	 create_table :event_browser_summaries do |t|
		t.integer :event_id
		t.datetime :time
		t.integer :period
		t.integer :count, default: 0
		t.string :browser_name
		t.string :browser_version
    end
  end
end
