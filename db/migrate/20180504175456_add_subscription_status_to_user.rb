class AddSubscriptionStatusToUser < ActiveRecord::Migration
  def change
    add_column :users, :subscription_status, :integer, default: 0
  end
end
