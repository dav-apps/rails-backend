class AddLinksToApp < ActiveRecord::Migration[4.2]
  def change
    add_column :apps, :link_web, :string
    add_column :apps, :link_play, :string
    add_column :apps, :link_windows, :string
  end
end
