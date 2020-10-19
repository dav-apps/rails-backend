class IndexUuidOnTableObject < ActiveRecord::Migration[5.2]
  def change
	add_index :table_objects, :uuid
  end
end
