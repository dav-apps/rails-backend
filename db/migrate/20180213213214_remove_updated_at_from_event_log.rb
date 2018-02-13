class RemoveUpdatedAtFromEventLog < ActiveRecord::Migration
  def change
    remove_column :event_logs, :updated_at, :datetime
  end
end
