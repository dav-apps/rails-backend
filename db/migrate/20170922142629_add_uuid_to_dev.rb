class AddUuidToDev < ActiveRecord::Migration[4.2]
  def change
    add_column :devs, :uuid, :string
  end
end
