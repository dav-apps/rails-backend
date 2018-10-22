class CreateNotificationProperty < ActiveRecord::Migration[5.1]
  def change
    create_table :notification_properties do |t|
      t.integer :notification_id
      t.string :name
      t.text :value
    end
  end
end
