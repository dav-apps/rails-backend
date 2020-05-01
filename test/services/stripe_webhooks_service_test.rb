require 'test_helper'
require 'stripe_mock'

class StripeWebhooksServiceTest < ActiveSupport::TestCase
	setup do
		StripeMock.start
		save_users_and_devs
   end

   teardown do
		StripeMock.stop
	end

   # InvoicePaymentSucceededEvent tests
	test "InvoicePaymentSucceededEvent should update the user from active free plan to active plus plan" do
		torera = users(:torera)
		period_end = 12312

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.lines.data[0].period.end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PLUS_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(1, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "InvoicePaymentSucceededEvent should update the user from active free plan to active pro plan" do
		torera = users(:torera)
		period_end = 1231234

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.lines.data[0].period.end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PRO_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(2, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "InvoicePaymentSucceededEvent should update the user from ending plus plan to active pro plan" do
		torera = users(:torera)
		period_end = 2394234

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.lines.data[0].period.end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PRO_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(2, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "InvoicePaymentSucceededEvent should create appropriate transfer for single provider" do
		# 10 € -> 1 PocketLib provider
		StripeMock.stop
		klaus = users(:klaus)
		amount = 1000
		transferred_amount = 1000 * 0.8

		# Get the customer
		payment_method = Stripe::PaymentMethod.list({
			customer: klaus.stripe_customer_id,
			type: 'card'
		}).data[0]

		# Create a payment intent
		payment_intent = Stripe::PaymentIntent.create({
			amount: amount,
			currency: 'eur',
			payment_method_types: ['card'],
			payment_method: payment_method.id,
			customer: klaus.stripe_customer_id,
			confirm: true
		})

		# Trigger the InvoicePaymentSucceeded event
		event = Hash.new
		event["id"] = "test_evt_1"
		event["livemode"] = false
		event["type"] = "invoice.payment_succeeded"
		event["object"] = "event"
		event["data"] = Hash.new
		event["data"]["object"] = Hash.new
		event["data"]["object"]["lines"] = Hash.new
		event["data"]["object"]["lines"]["data"] = Array.new([Hash.new])
		event["data"]["object"]["lines"]["data"][0]["period"] = Hash.new
		event["data"]["object"]["lines"]["data"][0]["plan"] = Hash.new

		event["data"]["object"]["customer"] = klaus.stripe_customer_id
		event["data"]["object"]["lines"]["data"][0]["period"]["end"] = 123456
		event["data"]["object"]["lines"]["data"][0]["plan"]["product"] = ENV['STRIPE_DAV_PRO_PRODUCT_ID']
		event["data"]["object"]["lines"]["data"][0]["amount"] = amount
		event["data"]["object"]["charge"] = payment_intent.charges.data[0].id

		StripeWebhooksService.InvoicePaymentSucceededEvent(Stripe::Util.convert_to_stripe_object(event))

		# Get the transfers
		transfers = Stripe::Transfer.list({limit: 1})
		transfer = transfers.data[0]

		assert_equal(800, transferred_amount)
		assert_equal(transferred_amount, transfer.amount)
		assert_equal("eur", transfer.currency)
		assert_equal(providers(:snicket).stripe_account_id, transfer.destination)
		assert_equal(payment_intent.charges.data[0].id, transfer.source_transaction)
	end

	test "InvoicePaymentSucceededEvent should create appropriate transfers for multiple providers" do
		# 10 € -> 2 PocketLib providers
		StripeMock.stop
		klaus = users(:klaus)
		amount = 1000
		transferred_amount = 400

		# Create a TableObjectUserAccess for Aus meinem Leben
		TableObjectUserAccess.create(
			table_object: table_objects(:ausMeinemLebenStoreBook),
			table_alias: tables(:StoreBook).id,
			user: klaus
		)

		# Get the customer
		payment_method = Stripe::PaymentMethod.list({
			customer: klaus.stripe_customer_id,
			type: 'card'
		}).data[0]

		# Create a payment intent
		payment_intent = Stripe::PaymentIntent.create({
			amount: amount,
			currency: 'eur',
			payment_method_types: ['card'],
			payment_method: payment_method.id,
			customer: klaus.stripe_customer_id,
			confirm: true
		})

		# Trigger the InvoicePaymentSucceeded event
		event = Hash.new
		event["id"] = "test_evt_1"
		event["livemode"] = false
		event["type"] = "invoice.payment_succeeded"
		event["object"] = "event"
		event["data"] = Hash.new
		event["data"]["object"] = Hash.new
		event["data"]["object"]["lines"] = Hash.new
		event["data"]["object"]["lines"]["data"] = Array.new([Hash.new])
		event["data"]["object"]["lines"]["data"][0]["period"] = Hash.new
		event["data"]["object"]["lines"]["data"][0]["plan"] = Hash.new

		event["data"]["object"]["customer"] = klaus.stripe_customer_id
		event["data"]["object"]["lines"]["data"][0]["period"]["end"] = 123456
		event["data"]["object"]["lines"]["data"][0]["plan"]["product"] = ENV['STRIPE_DAV_PRO_PRODUCT_ID']
		event["data"]["object"]["lines"]["data"][0]["amount"] = amount
		event["data"]["object"]["charge"] = payment_intent.charges.data[0].id

		StripeWebhooksService.InvoicePaymentSucceededEvent(Stripe::Util.convert_to_stripe_object(event))

		# Get the transfers
		transfers = Stripe::Transfer.list({limit: 2})
		firstTransfer = transfers.data[0]
		secondTransfer = transfers.data[1]

		assert_equal(400, transferred_amount)
		assert_equal(transferred_amount, firstTransfer.amount)
		assert_equal(transferred_amount, secondTransfer.amount)

		assert_equal("eur", secondTransfer.currency)
		assert_equal(providers(:snicket).stripe_account_id, secondTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, secondTransfer.source_transaction)

		assert_equal("eur", firstTransfer.currency)
		assert_equal(providers(:hindenburg).stripe_account_id, firstTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, firstTransfer.source_transaction)
	end

	test "InvoicePaymentSucceededEvent should create appropriate transfers for multiple providers with user using multiple apps" do
		# 10 € -> 2 PocketLib providers & 1 normal app
		StripeMock.stop
		klaus = users(:klaus)
		amount = 1000
		transferred_amount = 200

		# Create a TableObjectUserAccess for Aus meinem Leben
		TableObjectUserAccess.create(
			table_object: table_objects(:ausMeinemLebenStoreBook),
			table_alias: tables(:StoreBook).id,
			user: klaus
		)

		# Create a UsersApp for another app
		UsersApp.create(app: apps(:Cards), user: klaus)

		# Get the customer
		payment_method = Stripe::PaymentMethod.list({
			customer: klaus.stripe_customer_id,
			type: 'card'
		}).data[0]

		# Create a payment intent
		payment_intent = Stripe::PaymentIntent.create({
			amount: amount,
			currency: 'eur',
			payment_method_types: ['card'],
			payment_method: payment_method.id,
			customer: klaus.stripe_customer_id,
			confirm: true
		})

		# Trigger the InvoicePaymentSucceeded event
		event = Hash.new
		event["id"] = "test_evt_1"
		event["livemode"] = false
		event["type"] = "invoice.payment_succeeded"
		event["object"] = "event"
		event["data"] = Hash.new
		event["data"]["object"] = Hash.new
		event["data"]["object"]["lines"] = Hash.new
		event["data"]["object"]["lines"]["data"] = Array.new([Hash.new])
		event["data"]["object"]["lines"]["data"][0]["period"] = Hash.new
		event["data"]["object"]["lines"]["data"][0]["plan"] = Hash.new

		event["data"]["object"]["customer"] = klaus.stripe_customer_id
		event["data"]["object"]["lines"]["data"][0]["period"]["end"] = 123456
		event["data"]["object"]["lines"]["data"][0]["plan"]["product"] = ENV['STRIPE_DAV_PRO_PRODUCT_ID']
		event["data"]["object"]["lines"]["data"][0]["amount"] = amount
		event["data"]["object"]["charge"] = payment_intent.charges.data[0].id

		StripeWebhooksService.InvoicePaymentSucceededEvent(Stripe::Util.convert_to_stripe_object(event))

		# Get the transfers
		transfers = Stripe::Transfer.list({limit: 2})
		firstTransfer = transfers.data[0]
		secondTransfer = transfers.data[1]

		assert_equal(200, transferred_amount)
		assert_equal(transferred_amount, firstTransfer.amount)
		assert_equal(transferred_amount, secondTransfer.amount)

		assert_equal("eur", secondTransfer.currency)
		assert_equal(providers(:snicket).stripe_account_id, secondTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, secondTransfer.source_transaction)

		assert_equal("eur", firstTransfer.currency)
		assert_equal(providers(:hindenburg).stripe_account_id, firstTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, firstTransfer.source_transaction)
	end

	test "InvoicePaymentSucceededEvent should create appropriate transfers for multiple providers and multiple objects of the same provider with user using multiple apps" do
		# 10 € -> 2 PocketLib providers (2 first provider, 1 second provider) & 1 normal app
		StripeMock.stop
		klaus = users(:klaus)
		amount = 1000
		transferred_amount = 133

		# Create a TableObjectUserAccess for Aus meinem Leben and Series of Unfortunate Events 2
		TableObjectUserAccess.create(
			table_object: table_objects(:ausMeinemLebenStoreBook),
			table_alias: tables(:StoreBook).id,
			user: klaus
		)

		TableObjectUserAccess.create(
			table_object: table_objects(:seriesOfUnfortunateEventsSecondStoreBook),
			table_alias: tables(:StoreBook).id,
			user: klaus
		)

		# Create a UsersApp for another app
		UsersApp.create(app: apps(:Cards), user: klaus)

		# Get the customer
		payment_method = Stripe::PaymentMethod.list({
			customer: klaus.stripe_customer_id,
			type: 'card'
		}).data[0]

		# Create a payment intent
		payment_intent = Stripe::PaymentIntent.create({
			amount: amount,
			currency: 'eur',
			payment_method_types: ['card'],
			payment_method: payment_method.id,
			customer: klaus.stripe_customer_id,
			confirm: true
		})

		# Trigger the InvoicePaymentSucceeded event
		event = Hash.new
		event["id"] = "test_evt_1"
		event["livemode"] = false
		event["type"] = "invoice.payment_succeeded"
		event["object"] = "event"
		event["data"] = Hash.new
		event["data"]["object"] = Hash.new
		event["data"]["object"]["lines"] = Hash.new
		event["data"]["object"]["lines"]["data"] = Array.new([Hash.new])
		event["data"]["object"]["lines"]["data"][0]["period"] = Hash.new
		event["data"]["object"]["lines"]["data"][0]["plan"] = Hash.new

		event["data"]["object"]["customer"] = klaus.stripe_customer_id
		event["data"]["object"]["lines"]["data"][0]["period"]["end"] = 123456
		event["data"]["object"]["lines"]["data"][0]["plan"]["product"] = ENV['STRIPE_DAV_PRO_PRODUCT_ID']
		event["data"]["object"]["lines"]["data"][0]["amount"] = amount
		event["data"]["object"]["charge"] = payment_intent.charges.data[0].id

		StripeWebhooksService.InvoicePaymentSucceededEvent(Stripe::Util.convert_to_stripe_object(event))

		# Get the transfers
		transfers = Stripe::Transfer.list({limit: 2})
		firstTransfer = transfers.data[0]	# -> hindenburg
		secondTransfer = transfers.data[1]	# -> snicket

		assert_equal(133, transferred_amount)
		assert_equal(transferred_amount, firstTransfer.amount)
		assert_equal(transferred_amount * 2, secondTransfer.amount)

		assert_equal("eur", secondTransfer.currency)
		assert_equal(providers(:snicket).stripe_account_id, secondTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, secondTransfer.source_transaction)

		assert_equal("eur", firstTransfer.currency)
		assert_equal(providers(:hindenburg).stripe_account_id, firstTransfer.destination)
		assert_equal(payment_intent.charges.data[0].id, firstTransfer.source_transaction)
	end
   # end InvoicePaymentSucceededEvent tests

	# InvoicePaymentFailedEvent tests
	test "InvoicePaymentFailedEvent should not update the user after the first payment failed" do
		torera = users(:torera)
		original_plan = torera.plan
		original_subscription_status = torera.subscription_status
		original_period_end = torera.period_end

		# Create the event with paid = false and next_payment_attempt != nil
		event = StripeMock.mock_webhook_event('invoice.payment_failed')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.next_payment_attempt = Time.now + 2.weeks
		event.data.object.paid = false

		# Trigger the event
		StripeWebhooksService.InvoicePaymentFailedEvent(event)

		# The user should have the original values
		torera = users(:torera)
		assert_equal(original_plan, torera.plan)
		assert_equal(original_subscription_status, torera.subscription_status)
		assert_equal(original_period_end.to_i, torera.period_end.to_i)
	end

	test "InvoicePaymentFailedEvent should update the user to active free plan after the second payment failed" do
		torera = users(:torera)
		torera.period_end = Time.now + 3.weeks
		torera.save

		# Create the event with paid = false and next_payment_attempt = nil
		event = StripeMock.mock_webhook_event('invoice.payment_failed')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.next_payment_attempt = nil
		event.data.object.paid = false

		# Trigger the event
		StripeWebhooksService.InvoicePaymentFailedEvent(event)

		# The user should now be on the active free plan and no period_end
		torera = User.find_by_id(torera.id)
		assert_equal(0, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_nil(torera.period_end)
	end
	# End InvoicePaymentFailedEvent tests
	
	# CustomerSubscriptionCreatedEvent tests
	test "CustomerSubscriptionCreatedEvent should update the user to active plus plan" do
		torera = users(:torera)
		period_end = 123153123

		# Create the event
		event = StripeMock.mock_webhook_event('customer.subscription.created')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.items.data[0].plan.product = ENV["STRIPE_DAV_PLUS_PRODUCT_ID"]
		event.data.object.current_period_end = period_end

		# Trigger the event
		StripeWebhooksService.CustomerSubscriptionCreatedEvent(event)

		# The user should now be on the plus plan
		torera = User.find_by_id(torera.id)
		assert_equal(1, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "CustomerSubscriptionCreatedEvent should update the user to active pro plan" do
		torera = users(:torera)
		period_end = 123153123

		# Create the event
		event = StripeMock.mock_webhook_event('customer.subscription.created')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.items.data[0].plan.product = ENV["STRIPE_DAV_PRO_PRODUCT_ID"]
		event.data.object.current_period_end = period_end

		# Trigger the event
		StripeWebhooksService.CustomerSubscriptionCreatedEvent(event)

		# The user should now be on the pro plan
		torera = User.find_by_id(torera.id)
		assert_equal(2, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end
	# End CustomerSubscriptionCreatedEvent

   # CustomerSubscriptionUpdatedEvent tests
	test "CustomerSubscriptionUpdatedEvent with cancelling event should update the active plus plan to ending plus plan" do
		torera = users(:torera)
      period_end = Time.now + 1.month

      torera.plan = 1
      torera.subscription_status = 0
      torera.period_end = Time.now
      torera.save

      # Create the cancelling subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = true
      event.data.object.current_period_end = period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(1, torera.plan)
      assert_equal(1, torera.subscription_status)
      assert_equal(period_end.to_i, torera.period_end.to_i)
   end

	test "CustomerSubscriptionUpdatedEvent with cancelling event should update the active pro plan to ending pro plan" do
		torera = users(:torera)
      period_end = Time.now + 1.month

      torera.plan = 2
      torera.subscription_status = 0
      torera.period_end = Time.now
      torera.save

      # Create the cancelling subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = true
      event.data.object.current_period_end = period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(2, torera.plan)
      assert_equal(1, torera.subscription_status)
      assert_equal(period_end.to_i, torera.period_end.to_i)
   end

	test "CustomerSubscriptionUpdatedEvent with reactivating event should update the ending plus plan to active plus plan" do
		torera = users(:torera)
      period_end = Time.now + 1.month

      torera.plan = 1
      torera.subscription_status = 1
      torera.period_end = Time.now
      torera.save

      # Create the reactivating subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but with updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(1, torera.plan)
      assert_equal(0, torera.subscription_status)
      assert_equal(period_end.to_i, torera.period_end.to_i)
   end

   test "CustomerSubscriptionUpdatedEvent with reactivating event should update the ending pro plan to active pro plan" do
      torera = users(:torera)
      period_end = Time.now + 1.month

      torera.plan = 2
      torera.subscription_status = 1
      torera.period_end = Time.now
      torera.save

      # Create the reactivating subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but the new subscription_status and period_end
      torera = User.find_by_id(torera.id)
      assert_equal(2, torera.plan)
      assert_equal(0, torera.subscription_status)
      assert_equal(period_end.to_i, torera.period_end.to_i)
   end

	test "CustomerSubscriptionUpdatedEvent with different period_end should only update the period_end" do
		torera = users(:torera)
      plan = 2
      subscription_status = 0
      period_end = Time.now + 1.month

      torera.plan = plan
      torera.subscription_status = subscription_status
      torera.period_end = Time.now
      torera.save

      # Create the event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should have the same plan and subscription_status, but the new period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(subscription_status, torera.subscription_status)
      assert_equal(period_end.to_i, torera.period_end.to_i)
   end
   # End CustomerSubscriptionUpdatedEvent tests

   # CustomerSubscriptionDeletedEvent tests
	test "CustomerSubscriptionDeletedEvent should update the active plus plan to active free plan" do
		torera = users(:torera)
      period_end = Time.now + 1.month

      torera.plan = 1
      torera.subscription_status = 0
		torera.period_end = period_end
		torera.save

      # Create the event
      event = StripeMock.mock_webhook_event('customer.subscription.deleted')
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)

      # The user should now have a free plan with no period_end and active subscription_status
      torera = User.find_by_id(torera.id)
      assert_equal(0, torera.plan)
      assert_equal(0, torera.subscription_status)
      assert_nil(torera.period_end)
	end
	
	test "CustomerSubscriptionDeletedEvent should update the ending pro plan to active free plan" do
		torera = users(:torera)
		period_end = Time.now + 1.month

		torera.plan = 2
		torera.subscription_status = 1
		torera.period_end = period_end

		# Create the event
		event = StripeMock.mock_webhook_event('customer.subscription.deleted')
		event.data.object.customer = torera.stripe_customer_id

		# Trigger the event
		StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)
		
		# The user should now have a free plan with no period_end and active_subscription_status
		torera = User.find_by_id(torera.id)
		assert_equal(0, torera.plan)
		assert_equal(0, torera.subscription_status)
		assert_nil(torera.period_end)
	end
   # End CustomerSubscriptionDeletedEvent tests
end