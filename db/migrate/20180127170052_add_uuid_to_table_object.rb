class AddUuidToTableObject < ActiveRecord::Migration
  def change
    add_column :table_objects, :uuid, :string
  end
end
