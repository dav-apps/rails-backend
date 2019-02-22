class CreateEventSummary < ActiveRecord::Migration[5.1]
  def change
    create_table :event_summaries do |t|
      t.integer :event_id
      t.integer :period
      t.datetime :time
      t.integer :total, default: 0
    end
  end
end
