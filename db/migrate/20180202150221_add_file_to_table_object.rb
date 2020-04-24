class AddFileToTableObject < ActiveRecord::Migration[4.2]
  def change
    add_column :table_objects, :file, :boolean, default: false
  end
end
