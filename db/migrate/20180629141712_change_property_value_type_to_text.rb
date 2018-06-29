class ChangePropertyValueTypeToText < ActiveRecord::Migration
  def change
    change_column :properties, :value, :text
  end
end
