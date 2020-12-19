class WebPushSubscriptionDelegate
	attr_reader :web_push_subscription
	attr_accessor :id,
		:user_id,
		:uuid,
		:endpoint,
		:p256dh,
		:auth
	
	def initialize(attributes)
		attributes.transform_keys!(&:to_sym)

		@id = attributes[:id]
		@user_id = attributes[:user_id]
		@uuid = attributes[:uuid]
		@endpoint = attributes[:endpoint]
		@p256dh = attributes[:p256dh]
		@auth = attributes[:auth]

		@web_push_subscription = WebPushSubscriptionMigration.find_by(id: @id)
		@web_push_subscription = WebPushSubscriptionMigration.new(id: @id) if @web_push_subscription.nil?
	end

	def attributes
		{
			id: @id,
			user_id: @user_id,
			uuid: @uuid,
			endpoint: @endpoint,
			p256dh: @p256dh,
			auth: @auth
		}
	end

	def save
		# Copy the values to the web_push_subscription
		@web_push_subscription.user_id = @user_id
		@web_push_subscription.uuid = @uuid
		@web_push_subscription.endpoint = @endpoint
		@web_push_subscription.p256dh = @p256dh
		@web_push_subscription.auth = @auth
		delete_old = false

		# Check the id
		if @web_push_subscription.id.nil?
			# Get the ids for the last web_push_subscription in the old and new database
			last_subscription = WebPushSubscription.last
			last_subscription_migration = WebPushSubscriptionMigration.last

			if !last_subscription.nil? && !last_subscription_migration.nil?
				if last_subscription.id >= last_subscription_migration.id
					@web_push_subscription.id = last_subscription.id + 1
				else
					@web_push_subscription.id = last_subscription_migration.id + 1
				end
			elsif !last_subscription.nil?
				@web_push_subscription.id = last_subscription.id + 1
			elsif !last_subscription_migration.nil?
				@web_push_subscription.id = last_subscription_migration.id + 1
			end
		else
			delete_old = true
		end

		if @web_push_subscription.save
			@id = @web_push_subscription.id

			if delete_old
				# Check if the web_push_subscription is still in the old database
				old_subscription = WebPushSubscription.find_by(id: @id)
				old_subscription.destroy! if !old_subscription.nil?
			end

			return true
		end

		return false
	end

	def destroy
		# Delete the web_push_subscription in the old database
		subscription = WebPushSubscription.find_by(id: @id)
		subscription.destroy! if !subscription.nil?

		# Delete the web_push_subscription in the new database
		subscription = WebPushSubscriptionMigration.find_by(id: @id)
		subscription.destroy! if !subscription.nil?
	end

	def self.find_by(params)
		# Try to find the web_push_subscription in the new database
		subscription = WebPushSubscriptionMigration.find_by(params)
		return WebPushSubscriptionDelegate.new(subscription.attributes) if !subscription.nil?

		# Try to find the web_push_subscription in the old database
		subscription = WebPushSubscription.find_by(params)
		return subscription.nil? ? nil : WebPushSubscriptionDelegate.new(subscription.attributes)
	end

	def self.where(params)
		result = Array.new

		# Get the web_push_subscriptions from the new database
		WebPushSubscriptionMigration.where(params).each do |web_push_subscription|
			result.push(WebPushSubscriptionDelegate.new(web_push_subscription.attributes))
		end

		# Get the web_push_subscriptions from the old database
		WebPushSubscription.where(params).each do |web_push_subscription|
			# Check if the web_push_subscription is already in the results
			next if result.any? { |s| s.id == web_push_subscription.id }
			result.push(WebPushSubscriptionDelegate.new(web_push_subscription.attributes))
		end

		return result
	end
end