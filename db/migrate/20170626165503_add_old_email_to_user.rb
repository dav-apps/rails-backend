class AddOldEmailToUser < ActiveRecord::Migration
  def change
    add_column :users, :old_email, :string
  end
end
