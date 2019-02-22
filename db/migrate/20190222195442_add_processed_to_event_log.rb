class AddProcessedToEventLog < ActiveRecord::Migration[5.1]
  def change
    add_column :event_logs, :processed, :boolean, default: false
  end
end
