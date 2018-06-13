class AddTimestampsToUsersApps < ActiveRecord::Migration
  def change
    add_column :users_apps, :created_at, :datetime, null: false
    add_column :users_apps, :updated_at, :datetime, null: false
  end
end
