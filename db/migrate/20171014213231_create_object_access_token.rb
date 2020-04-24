class CreateObjectAccessToken < ActiveRecord::Migration[4.2]
  def change
    create_table :object_access_tokens do |t|
      t.integer :table_object_id
      t.string :access_token
      t.timestamps
    end
  end
end
