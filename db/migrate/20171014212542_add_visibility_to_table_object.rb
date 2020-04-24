class AddVisibilityToTableObject < ActiveRecord::Migration[4.2]
  def change
    add_column :table_objects, :visibility, :integer, default: 0
  end
end
