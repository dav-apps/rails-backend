class AddOldEmailToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :old_email, :string
  end
end
