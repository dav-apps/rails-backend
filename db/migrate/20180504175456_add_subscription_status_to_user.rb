class AddSubscriptionStatusToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :subscription_status, :integer, default: 0
  end
end
