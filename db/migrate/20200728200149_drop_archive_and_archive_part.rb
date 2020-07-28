class DropArchiveAndArchivePart < ActiveRecord::Migration[5.2]
  def change
	drop_table :archives
	drop_table :archive_parts
  end
end
