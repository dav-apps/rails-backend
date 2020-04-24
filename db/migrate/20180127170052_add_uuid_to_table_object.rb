class AddUuidToTableObject < ActiveRecord::Migration[4.2]
  def change
    add_column :table_objects, :uuid, :string
  end
end
