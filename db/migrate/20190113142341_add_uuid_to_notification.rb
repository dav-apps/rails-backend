class AddUuidToNotification < ActiveRecord::Migration[5.1]
  def change
    add_column :notifications, :uuid, :string
  end
end
