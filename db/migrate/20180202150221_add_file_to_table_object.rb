class AddFileToTableObject < ActiveRecord::Migration
  def change
    add_column :table_objects, :file, :boolean, default: false
  end
end
