class UserDelegate
	attr_reader :user
	attr_accessor :id,
		:username,
		:email,
		:confirmed,
		:password_digest,
		:email_confirmation_token,
		:password_confirmation_token,
		:old_email,
		:new_email,
		:new_password,
		:used_storage,
		:last_active,
		:stripe_customer_id,
		:plan,
		:subscription_status,
		:period_end,
		:created_at,
		:updated_at

	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@username = !attributes[:first_name].nil? ? attributes[:first_name] : attributes[:username]
		@email = attributes[:email]
		@confirmed = attributes[:confirmed]
		@password_digest = attributes[:password_digest]
		@email_confirmation_token = attributes[:email_confirmation_token]
		@password_confirmation_token = attributes[:password_confirmation_token]
		@old_email = attributes[:old_email]
		@new_email = attributes[:new_email]
		@new_password = attributes[:new_password]
		@used_storage = attributes[:used_storage]
		@last_active = attributes[:last_active]
		@stripe_customer_id = attributes[:stripe_customer_id]
		@plan = attributes[:plan]
		@subscription_status = attributes[:subscription_status]
		@period_end = attributes[:period_end]
		@created_at = attributes[:created_at]
		@updated_at = attributes[:updated_at]

		@user = UserMigration.find_by(id: @id)
		@user = UserMigration.new(id: @id) if @user.nil?
	end

	def attributes
		{
			id: @id,
			username: @username,
			email: @email,
			confirmed: @confirmed,
			password_digest: @password_digest,
			email_confirmation_token: @email_confirmation_token,
			password_confirmation_token: @password_confirmation_token,
			old_email: @old_email,
			new_email: @new_email,
			new_password: @new_password,
			used_storage: @used_storage,
			last_active: @last_active,
			stripe_customer_id: @stripe_customer_id,
			plan: @plan,
			subscription_status: @subscription_status,
			period_end: @period_end,
			created_at: @created_at,
			updated_at: @updated_at
		}
	end

	def save
		# Copy the values to the user
		@user.first_name = @username
		@user.email = @email
		@user.confirmed = @confirmed
		@user.password_digest = @password_digest
		@user.email_confirmation_token = @email_confirmation_token
		@user.password_confirmation_token = @password_confirmation_token
		@user.old_email = @old_email
		@user.new_email = @new_email
		@user.new_password = @new_password
		@user.used_storage = @used_storage
		@user.last_active = @last_active
		@user.stripe_customer_id = @stripe_customer_id
		@user.plan = @plan
		@user.subscription_status = @subscription_status
		@user.period_end = @period_end
		@user.created_at = @created_at
		@user.updated_at = @updated_at
		delete_old = false

		# Check the id
		if @user.id.nil?
			# Get the ids for the last api in the old and new database
			last_user = User.last
			last_user_migration = UserMigration.last

			if !last_user.nil? && !last_user_migration.nil?
				if last_user.id >= last_user_migration.id
					@user.id = last_user.id + 1
				else
					@user.id = last_user_migration.id + 1
				end
			elsif !last_user.nil?
				@user.id = last_user.id + 1
			elsif !last_user_migration.nil?
				@user.id = last_user_migration.id + 1
			end
		else
			delete_old = true
		end

		if @user.save
			@id = @user.id
			@created_at = @user.created_at
			@updated_at = @user.updated_at

			if delete_old
				# Check if the user is still in the old database
				old_user = User.find_by(id: @id)
				old_user.destroy! if !old_user.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the devs of the user
		DevDelegate.where(user_id: @id).each { |dev| dev.destroy }

		# Delete the notifications of the user
		NotificationDelegate.where(user_id: @id).each { |notification| notification.destroy }

		# Delete the providers of the user
		ProviderDelegate.where(user_id: @id).each { |provider| provider.destroy }

		# Delete the purchases of the user
		PurchaseDelegate.where(user_id: @id).each { |purchase| purchase.destroy }

		# Delete the sessions of the user
		SessionDelegate.where(user_id: @id).each { |session| session.destroy }

		# Delete the table_objects of the user
		TableObjectDelegate.where(user_id: @id).each { |table_object| table_object.destroy }

		# Delete the table_object_user_accesses of the user
		TableObjectUserAccess.where(user_id: @id).each { |user_access| user_access.destroy }

		# Delete the users_apps of the user
		UsersAppDelegate.where(user_id: @id).each { |users_app| users_app.destroy }

		# Delete the web_push_subscriptions of the user
		WebPushSubscriptionDelegate.where(user_id: @id).each { |web_push_subscription| web_push_subscription.destroy }

		# Delete the user in the old database
		user = User.find_by(id: @id)
		user.destroy! if !user.nil?

		# Delete the user in the new database
		user = UserMigration.find_by(id: @id)
		user.destroy! if !user.nil?
	end

	def self.find_by(params)
		# Try to find the user in the new database
		u = UserMigration.find_by(params)
		return UserDelegate.new(u.attributes) if !u.nil?

		# Try to find the user in the old database
		u = User.find_by(params)
		return u.nil? ? nil : UserDelegate.new(u.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the users from the new database
		UserMigration.where(params).each do |user|
			result.push(UserDelegate.new(user.attributes))
		end

		# Get the users from the old database
		User.where(params).each do |user|
			# Check if the user is already in the results
			next if result.any? { |u| u.id == user.id }
			result.push(UserDelegate.new(user.attributes))
		end

		return result
	end
end