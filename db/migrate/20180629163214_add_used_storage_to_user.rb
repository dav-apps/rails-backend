class AddUsedStorageToUser < ActiveRecord::Migration
  def change
    add_column :users, :used_storage, :integer, :limit => 8, default: 0
  end
end
