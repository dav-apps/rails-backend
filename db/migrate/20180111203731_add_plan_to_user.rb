class AddPlanToUser < ActiveRecord::Migration
  def change
    add_column :users, :plan, :integer, default: 0
  end
end
