class AddUsedStorageToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :used_storage, :integer, :limit => 8, default: 0
  end
end
