class CreateArchivePart < ActiveRecord::Migration[5.1]
  def change
    create_table :archive_parts do |t|
      t.integer :archive_id
      t.string :name
    end
  end
end
