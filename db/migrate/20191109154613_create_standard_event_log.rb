class CreateStandardEventLog < ActiveRecord::Migration[5.2]
  def change
	 create_table :standard_event_logs do |t|
		t.integer :event_id
		t.boolean :processed, default: false
		t.string :browser_name
		t.string :browser_version
		t.string :os_name
		t.string :os_version
		t.string :country
		t.datetime :created_at
    end
  end
end
