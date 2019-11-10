class CreateEventOsSummary < ActiveRecord::Migration[5.2]
  def change
	 create_table :event_os_summaries do |t|
		t.integer :event_id
		t.datetime :time
		t.integer :period
		t.integer :count, default: 0
		t.string :os_name
		t.string :os_version
    end
  end
end
