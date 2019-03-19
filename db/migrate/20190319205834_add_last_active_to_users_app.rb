class AddLastActiveToUsersApp < ActiveRecord::Migration[5.1]
  def change
    add_column :users_apps, :last_active, :datetime
  end
end
