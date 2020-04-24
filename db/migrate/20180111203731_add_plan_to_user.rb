class AddPlanToUser < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :plan, :integer, default: 0
  end
end
