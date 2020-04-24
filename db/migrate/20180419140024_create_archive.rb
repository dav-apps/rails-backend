class CreateArchive < ActiveRecord::Migration[4.2]
  def change
    create_table :archives do |t|
      t.integer :user_id
      t.timestamps
    end
  end
end
