class StripeWebhooksService
	def self.InvoicePaymentSucceededEvent(event)
		customer_id = event.data.object.customer
		period_end = event.data.object.lines.data[0].period.end if event.data.object.lines.data.count > 0
		product_id = event.data.object.lines.data[0].plan.product if event.data.object.lines.data.count > 0
		amount = event.data.object.lines.data[0].amount
		charge = event.data.object.charge
		
		if customer_id
			user = User.find_by(stripe_customer_id: customer_id)
		end

      if user
         # Update the user with new period_end and plan value
         user.period_end = Time.at(period_end) if period_end
         user.subscription_status = 0
         
         case product_id
         when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
            user.plan = 2
         end
         
			user.save

			# Get all apps of the user
			apps = Array.new		# Array<{id: int, providers: Array<{id: int, count: int}>}>

			user.apps.where(published: true).each do |app|
				hash = Hash.new
				apps.push({
					id: app.id,
					providers: Array.new
				})
			end

			if apps.size > 0
				# Go through each TableObjectUserAccess of the user
				user.table_object_user_access.each do |access|
					next if access.table_object.user == user
					next if !access.table_object.user.provider
					app_id = access.table_object.table.app.id
					provider_id = access.table_object.user.provider.id

					# Add the provider to the app
					app_index = apps.index { |app| app[:id] == app_id }
					next if !app_index

					# Find the provider in the app
					provider_index = apps[app_index][:providers].index { |provider| provider[:id] == provider_id }

					if !provider_index
						# Add the provider to the app
						apps[app_index][:providers].push({
							id: provider_id,
							count: 1
						})
					else
						# Increase the count of the provider
						apps[app_index][:providers][provider_index][:count] = apps[app_index][:providers][provider_index][:count] + 1
					end
				end

				# Calculate the shares and send the money to the providers
				app_share = (amount * 0.8).round / apps.size

				apps.each do |app|
					next if app[:providers].size == 0
					total_share_count = 0

					app[:providers].each do |provider_hash|
						total_share_count = total_share_count + provider_hash[:count]
					end

					share = app_share / total_share_count

					# TODO: Send the app share to the appropriate dev if necessary

					app[:providers].each do |provider_hash|
						# Get the provider
						provider = Provider.find_by_id(provider_hash[:id])
						provider_amount = share * provider_hash[:count]

						# Get the connected account from the Stripe API
						connected_account = Stripe::Account.retrieve(provider.stripe_account_id)
						next if !connected_account

						# TODO: Check if the connected account is in a SEPA country

						# Create the transfer
						transfer = Stripe::Transfer.create({
							amount: provider_amount,
							currency: 'eur',
							destination: provider.stripe_account_id,
							source_transaction: charge
						})
					end
				end
			end
      end

      200
   end

   def self.InvoicePaymentFailedEvent(event)
      # With the second unsuccessful attempt to charge the customer, set the plan to 0 and send the email
      paid = event.data.object.paid
      next_payment_attempt = event.data.object.next_payment_attempt

      if !paid && !next_payment_attempt
         # Change the plan to free
			customer_id = event.data.object.customer
			
			if customer_id
				user = User.find_by(stripe_customer_id: customer_id)
			end
         
         if user
            user.plan = 0
            user.subscription_status = 0
            user.period_end = nil
            user.save

            # Send the email
            UserNotifier.send_failed_payment_email(user).deliver_later
         end
      end

      200
	end
	
	def self.CustomerSubscriptionCreatedEvent(event)
		period_end = event.data.object.current_period_end
		product_id = event.data.object.items.data[0].plan.product if event.data.object.items.data.count > 0
		customer_id = event.data.object.customer
		
		if customer_id
			user = User.find_by(stripe_customer_id: customer_id)
		end
		
		if user
			user.subscription_status = 0

			if period_end
				user.period_end = Time.at(period_end)
			end

			case product_id
         when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
            user.plan = 2
			end
			
			user.save
		end

		200
	end

	def self.CustomerSubscriptionUpdatedEvent(event)
      cancelled = event.data.object.cancel_at_period_end
		period_end = event.data.object.current_period_end
		product_id = event.data.object.items.data[0].plan.product if event.data.object.items.data.count > 0
		customer_id = event.data.object.customer
		
		if customer_id
			user = User.find_by(stripe_customer_id: customer_id)
		end

      if user
         if cancelled
            user.subscription_status = 1     # Change the subscription_status to ending
         else
            user.subscription_status = 0     # Change the subscription_status to active
         end
         
         if period_end
            user.period_end = Time.at(period_end)
			end
			
			case product_id
			when ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
				user.plan = 1
			when ENV['STRIPE_DAV_PRO_PRODUCT_ID']
				user.plan = 2
			end

         user.save
      end

      200
   end

   def self.CustomerSubscriptionDeletedEvent(event)
		customer_id = event.data.object.customer
		
      if customer_id
         user = User.find_by(stripe_customer_id: customer_id)
      end

      if user
         # Downgrade the plan to free, clear the period_end field and change the subscription_status to active
         user.plan = 0
         user.subscription_status = 0
         user.period_end = nil
         user.save
      end

      200
	end
end