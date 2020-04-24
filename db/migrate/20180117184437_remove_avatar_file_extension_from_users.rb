class RemoveAvatarFileExtensionFromUsers < ActiveRecord::Migration[4.2]
  def change
    remove_column :users, :avatar_file_extension, :string
  end
end
