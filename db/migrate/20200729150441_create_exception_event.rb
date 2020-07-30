class CreateExceptionEvent < ActiveRecord::Migration[5.2]
  def change
	 create_table :exception_events do |t|
		t.integer :app_id
		t.datetime :created_at
		t.string :name
		t.string :message
		t.text :stack_trace
		t.string :app_version
		t.string :os_version
		t.string :device_family
		t.string :locale
    end
  end
end
