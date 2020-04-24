class AddDataToEventLogs < ActiveRecord::Migration[4.2]
  def change
    add_column :event_logs, :data, :string
  end
end
