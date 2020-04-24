class ChangeEventLogDataTypeToText < ActiveRecord::Migration[4.2]
  def change
    change_column :event_logs, :data, :text
  end
end
