class CreateStandardEventSummary < ActiveRecord::Migration[5.2]
  def change
	 create_table :standard_event_summaries do |t|
		t.integer :event_id
		t.datetime :time
		t.integer :period
		t.integer :total, default: 0
    end
  end
end
