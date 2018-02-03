class RenameObjectAccessTokenToAccessToken < ActiveRecord::Migration
  def change
    rename_table :object_access_tokens, :access_tokens
    remove_column :access_tokens, :table_object_id, :integer
    rename_column :access_tokens, :access_token, :token
  end
end
