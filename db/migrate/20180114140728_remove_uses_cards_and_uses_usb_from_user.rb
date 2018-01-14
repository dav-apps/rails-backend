class RemoveUsesCardsAndUsesUsbFromUser < ActiveRecord::Migration
  def change
    remove_column :users, :uses_cards, :boolean
    remove_column :users, :uses_usb, :boolean
  end
end
