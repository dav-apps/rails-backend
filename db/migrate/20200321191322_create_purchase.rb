class CreatePurchase < ActiveRecord::Migration[5.2]
  def change
	 create_table :purchases do |t|
		t.integer :user_id
		t.integer :table_object_id
		t.string :payment_intent_id
		t.string :product_image
		t.string :product_name
		t.string :provider_image
		t.string :provider_name
		t.integer :price
		t.string :currency
		t.boolean :completed, default: false
		t.timestamps
    end
  end
end
