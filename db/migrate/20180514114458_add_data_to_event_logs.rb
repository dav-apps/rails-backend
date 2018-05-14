class AddDataToEventLogs < ActiveRecord::Migration
  def change
    add_column :event_logs, :data, :string
  end
end
