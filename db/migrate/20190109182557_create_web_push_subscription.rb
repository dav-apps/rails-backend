class CreateWebPushSubscription < ActiveRecord::Migration[5.1]
  def change
    create_table :web_push_subscriptions do |t|
      t.integer :user_id
      t.string :uuid
      t.string :endpoint
      t.string :p256dh
      t.string :auth
    end
  end
end
