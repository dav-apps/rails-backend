class AddUuidToDev < ActiveRecord::Migration
  def change
    add_column :devs, :uuid, :string
  end
end
