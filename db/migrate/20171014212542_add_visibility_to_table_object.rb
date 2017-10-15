class AddVisibilityToTableObject < ActiveRecord::Migration
  def change
    add_column :table_objects, :visibility, :integer, default: 0
  end
end
