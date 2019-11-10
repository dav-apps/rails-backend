class CreateEventCountrySummary < ActiveRecord::Migration[5.2]
  def change
	 create_table :event_country_summaries do |t|
		t.integer :event_id
		t.datetime :time
		t.integer :period
		t.integer :count, default: 0
		t.string :country
    end
  end
end
