class CreateApiError < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_errors do |t|
		t.integer :api_id
		t.integer :code
		t.string :message
    end
  end
end
