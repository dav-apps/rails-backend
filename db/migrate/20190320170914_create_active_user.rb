class CreateActiveUser < ActiveRecord::Migration[5.1]
  def change
    create_table :active_users do |t|
      t.datetime :time
      t.integer :count_daily
      t.integer :count_monthly
      t.integer :count_yearly
    end
  end
end
