class AddPeriodEndToUser < ActiveRecord::Migration
  def change
    add_column :users, :period_end, :timestamp
  end
end
