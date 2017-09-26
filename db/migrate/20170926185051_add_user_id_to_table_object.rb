class AddUserIdToTableObject < ActiveRecord::Migration
  def change
    add_column :table_objects, :user_id, :integer
  end
end
