class AddNameAndCompletedToArchive < ActiveRecord::Migration[4.2]
  def change
    add_column :archives, :name, :string
    add_column :archives, :completed, :boolean, default: false
  end
end
