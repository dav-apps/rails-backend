class CreateEventLogProperty < ActiveRecord::Migration[4.2]
  def change
    create_table :event_log_properties do |t|
      t.integer :event_log_id
      t.string :name
      t.text :value
    end
  end
end
