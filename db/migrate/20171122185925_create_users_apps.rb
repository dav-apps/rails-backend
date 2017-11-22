class CreateUsersApps < ActiveRecord::Migration
  def change
    create_table :users_apps do |t|
      t.integer :user_id
      t.integer :app_id
    end
  end
end
