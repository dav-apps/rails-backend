class CreateUser < ActiveRecord::Migration[4.2]
  def change
    create_table :users do |t|
      t.string :email
      t.string :password_digest
      t.string :username
      t.boolean :confirmed, default: false
      t.string :email_confirmation_token
      t.string :password_confirmation_token
      t.string :new_password
      t.string :new_email
      t.string :avatar_file_extension
      t.timestamps
    end
  end
end
