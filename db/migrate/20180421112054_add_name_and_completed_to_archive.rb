class AddNameAndCompletedToArchive < ActiveRecord::Migration
  def change
    add_column :archives, :name, :string
    add_column :archives, :completed, :boolean, default: false
  end
end
