class CreateDev < ActiveRecord::Migration[4.2]
  def change
    create_table :devs do |t|
      t.integer :user_id
      t.string :api_key
      t.string :secret_key
      t.timestamps
    end
  end
end
