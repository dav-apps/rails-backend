class RemoveDataFromEventLog < ActiveRecord::Migration[4.2]
  def change
    remove_column :event_logs, :data, :text
  end
end
