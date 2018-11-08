class AddLastActiveToUser < ActiveRecord::Migration[5.1]
  def change
    add_column :users, :last_active, :datetime
  end
end
