class RemoveAvatarFileExtensionFromUsers < ActiveRecord::Migration
  def change
    remove_column :users, :avatar_file_extension, :string
  end
end
