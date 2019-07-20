class AddCreatedAtToSession < ActiveRecord::Migration[5.1]
  def change
		add_column :sessions, :created_at, :datetime
  end
end
