class AddEtagToTableObject < ActiveRecord::Migration[6.0]
  def change
	add_column :table_objects, :etag, :string
  end
end
