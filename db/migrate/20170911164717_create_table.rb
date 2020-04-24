class CreateTable < ActiveRecord::Migration[4.2]
  def change
    create_table :tables do |t|
      t.integer :app_id
      t.string :name
      t.timestamps
    end
  end
end
