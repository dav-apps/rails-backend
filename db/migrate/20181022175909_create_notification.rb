class CreateNotification < ActiveRecord::Migration[5.1]
  def change
    create_table :notifications do |t|
      t.integer :app_id
      t.integer :user_id
      t.datetime :time
      t.integer :interval
    end
  end
end
