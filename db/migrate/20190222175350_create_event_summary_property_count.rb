class CreateEventSummaryPropertyCount < ActiveRecord::Migration[5.1]
  def change
    create_table :event_summary_property_counts do |t|
      t.integer :event_summary_id
      t.string :name
      t.text :value
      t.integer :count, default: 0
    end
  end
end
