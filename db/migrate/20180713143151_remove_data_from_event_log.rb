class RemoveDataFromEventLog < ActiveRecord::Migration
  def change
    remove_column :event_logs, :data, :text
  end
end
