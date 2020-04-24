class CreateEvent < ActiveRecord::Migration[4.2]
  def change
    create_table :events do |t|
      t.string :name
      t.integer :app_id
      t.timestamps
    end
  end
end
