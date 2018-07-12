class ChangeEventLogDataTypeToText < ActiveRecord::Migration
  def change
    change_column :event_logs, :data, :text
  end
end
