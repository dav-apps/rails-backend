class CreateProvider < ActiveRecord::Migration[5.2]
  def change
	 create_table :providers do |t|
		t.integer :user_id
		t.string :stripe_account_id
		t.timestamps
    end
  end
end
