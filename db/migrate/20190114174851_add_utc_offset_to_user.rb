class AddUtcOffsetToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :utc_offset, :integer, default: 0
  end
end
