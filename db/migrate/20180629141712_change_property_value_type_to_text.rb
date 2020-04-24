class ChangePropertyValueTypeToText < ActiveRecord::Migration[4.2]
  def change
    change_column :properties, :value, :text
  end
end
