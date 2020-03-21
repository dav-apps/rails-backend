class CreatePurchase < ActiveRecord::Migration[5.2]
  def change
	 create_table :purchases do |t|
		t.integer :user_id
		t.integer :table_object_id
		t.integer :price
		t.string :currency
		t.boolean :paid, default: false
		t.timestamps
    end
  end
end
