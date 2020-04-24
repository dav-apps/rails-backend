class CreateTableObjectsAccessTokens < ActiveRecord::Migration[4.2]
  def change
    create_table :table_objects_access_tokens do |t|
      t.integer :table_object_id
      t.integer :access_token_id
    end
  end
end
