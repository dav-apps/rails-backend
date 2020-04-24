class AddUserIdToTableObject < ActiveRecord::Migration[4.2]
  def change
    add_column :table_objects, :user_id, :integer
  end
end
