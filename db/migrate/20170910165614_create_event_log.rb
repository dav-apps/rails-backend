class CreateEventLog < ActiveRecord::Migration[4.2]
  def change
    create_table :event_logs do |t|
      t.integer :event_id
      t.timestamps
    end
  end
end
