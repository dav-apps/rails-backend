class AddLinksToApp < ActiveRecord::Migration
  def change
    add_column :apps, :link_web, :string
    add_column :apps, :link_play, :string
    add_column :apps, :link_windows, :string
  end
end
