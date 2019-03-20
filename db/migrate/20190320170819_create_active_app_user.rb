class CreateActiveAppUser < ActiveRecord::Migration[5.1]
  def change
    create_table :active_app_users do |t|
      t.integer :app_id
      t.datetime :time
      t.integer :count_daily
      t.integer :count_monthly
      t.integer :count_yearly
    end
  end
end
