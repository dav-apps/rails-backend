class CreateApiEnvVar < ActiveRecord::Migration[5.2]
  def change
	 create_table :api_env_vars do |t|
		t.integer :api_id
		t.string :name
		t.string :value
		t.string :class_name
    end
  end
end
