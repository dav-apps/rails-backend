class AddUsedStorageToUsersApps < ActiveRecord::Migration
  def change
    add_column :users_apps, :used_storage, :integer, :limit => 8, default: 0
  end
end
