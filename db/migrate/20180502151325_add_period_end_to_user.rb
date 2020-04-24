class AddPeriodEndToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :period_end, :timestamp
  end
end
