class RemoveUpdatedAtFromEventLog < ActiveRecord::Migration[4.2]
  def change
    remove_column :event_logs, :updated_at, :datetime
  end
end
