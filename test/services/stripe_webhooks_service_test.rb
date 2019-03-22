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
		old_plan = 0
		new_plan = 1
		subscription_status = 0
		period_end = 12312
		
		torera = users(:torera)
		torera.plan = old_plan
		torera.subscription_status = subscription_status
		torera.period_end = period_end

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.period_end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PLUS_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(new_plan, torera.plan)
		assert_equal(subscription_status, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "InvoicePaymentSucceededEvent should update the user from active free plan to active pro plan" do
		old_plan = 0
		new_plan = 2
		subscription_status = 0
		period_end = 1231234

		torera = users(:torera)
		torera.plan = old_plan
		torera.subscription_status = subscription_status
		torera.period_end = period_end

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.period_end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PRO_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(new_plan, torera.plan)
		assert_equal(subscription_status, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end

	test "InvoicePaymentSucceededEvent should update the user from ending plus plan to active pro plan" do
		old_plan = 1
		new_plan = 2
		old_subscription_status = 1
		new_subscription_status = 0
		period_end = 2394234

		torera = users(:torera)
		torera.plan = old_plan
		torera.subscription_status = old_subscription_status
		torera.period_end = period_end

		# Create the event
		event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.period_end = period_end
		event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PRO_PRODUCT_ID']

		# Trigger the event
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)

		# The user should now have an active plus plan with the given period_end
		torera = User.find_by_id(torera.id)
		assert_equal(new_plan, torera.plan)
		assert_equal(new_subscription_status, torera.subscription_status)
		assert_equal(period_end, torera.period_end.to_i)
	end
   # end InvoicePaymentSucceededEvent tests

	# InvoicePaymentFailedEvent tests
	test "InvoicePaymentFailedEvent should not update the user after the first payment failed" do
		plan = 2
		subscription_status = 1
		period_end = Time.now + 1.month

		torera = users(:torera)
		torera.plan = plan
		torera.subscription_status = subscription_status
		torera.period_end = period_end

		# Create the event with paid = false and next_payment_attempt != nil
		event = StripeMock.mock_webhook_event('invoice.payment_failed')
		event.data.object.customer = torera.stripe_customer_id
		event.data.object.next_payment_attempt = Time.now + 2.weeks
		event.data.object.paid = false

		# Trigger the event
		StripeWebhooksService.InvoicePaymentFailedEvent(event)

		# The user should have the original values
		torera = users(:torera)
		assert_equal(plan, torera.plan)
		assert_equal(subscription_status, torera.subscription_status)
		assert_equal(period_end.to_i, torera.period_end.to_i)
	end

	test "InvoicePaymentFailedEvent should update the user to active free plan after the second payment failed" do
		old_plan = 1
		new_plan = 0
		old_subscription_status = 1
		new_subscription_status = 0
		period_end = Time.now + 1.month
		
		torera = users(:torera)
		torera.plan = old_plan
		torera.subscription_status = old_subscription_status
		torera.period_end = period_end
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
		assert_equal(new_plan, torera.plan)
		assert_equal(new_subscription_status, torera.subscription_status)
		assert_nil(torera.period_end)
	end
   # End InvoicePaymentFailedEvent tests

   # CustomerSubscriptionUpdatedEvent tests
   test "CustomerSubscriptionUpdatedEvent with cancelling event should update the active plus plan to ending plus plan" do
      plan = 1
      old_subscription_status = 0
      new_subscription_status = 1
      old_period_end = Time.now
      new_period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = plan
      torera.subscription_status = old_subscription_status
      torera.period_end = old_period_end
      torera.save

      # Create the cancelling subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = true
      event.data.object.current_period_end = new_period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(new_subscription_status, torera.subscription_status)
      assert_equal(new_period_end.to_i, torera.period_end.to_i)
   end

   test "CustomerSubscriptionUpdatedEvent with cancelling event should update the active pro plan to ending pro plan" do
      plan = 2
      old_subscription_status = 0
      new_subscription_status = 1
      old_period_end = Time.now
      new_period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = plan
      torera.subscription_status = old_subscription_status
      torera.period_end = old_period_end
      torera.save

      # Create the cancelling subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = true
      event.data.object.current_period_end = new_period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(new_subscription_status, torera.subscription_status)
      assert_equal(new_period_end.to_i, torera.period_end.to_i)
   end

   test "CustomerSubscriptionUpdatedEvent with reactivating event should update the ending plus plan to active plus plan" do
      plan = 1
      old_subscription_status = 1
      new_subscription_status = 0
      old_period_end = Time.now
      new_period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = plan
      torera.subscription_status = old_subscription_status
      torera.period_end = old_period_end
      torera.save

      # Create the reactivating subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = new_period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but with updated subscription_status and updated period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(new_subscription_status, torera.subscription_status)
      assert_equal(new_period_end.to_i, torera.period_end.to_i)
   end

   test "CustomerSubscriptionUpdatedEvent with reactivating event should update the ending pro plan to active pro plan" do
      plan = 2
      old_subscription_status = 1
      new_subscription_status = 0
      old_period_end = Time.now
      new_period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = plan
      torera.subscription_status = old_subscription_status
      torera.period_end = old_period_end
      torera.save

      # Create the reactivating subscription event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = new_period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should now have the same plan, but the new subscription_status and period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(new_subscription_status, torera.subscription_status)
      assert_equal(new_period_end.to_i, torera.period_end.to_i)
   end

   test "CustomerSubscriptionUpdatedEvent with different period_end should only update the period_end" do
      plan = 2
      subscription_status = 0
      old_period_end = Time.now
      new_period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = plan
      torera.subscription_status = subscription_status
      torera.period_end = old_period_end
      torera.save

      # Create the event
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = new_period_end
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # The user should have the same plan and subscription_status, but the new period_end
      torera = User.find_by_id(torera.id)
      assert_equal(plan, torera.plan)
      assert_equal(subscription_status, torera.subscription_status)
      assert_equal(new_period_end.to_i, torera.period_end.to_i)
   end
   # End CustomerSubscriptionUpdatedEvent tests

   # CustomerSubscriptionDeletedEvent tests
   test "CustomerSubscriptionDeletedEvent should update the active plus plan to active free plan" do
      old_plan = 1
      new_plan = 0
      subscription_status = 0
      period_end = Time.now + 1.month

      torera = users(:torera)
      torera.plan = old_plan
      torera.subscription_status = subscription_status
      torera.period_end = period_end

      # Create the event
      event = StripeMock.mock_webhook_event('customer.subscription.deleted')
      event.data.object.customer = torera.stripe_customer_id

      # Trigger the event
      StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)

      # The user should now have a free plan with no period_end and active subscription_status
      torera = User.find_by_id(torera.id)
      assert_equal(new_plan, torera.plan)
      assert_equal(subscription_status, torera.subscription_status)
      assert_nil(torera.period_end)
	end
	
	test "CustomerSubscriptionDeletedEvent should update the ending pro plan to active free plan" do
		old_plan = 2
		new_plan = 0
		old_subscription_status = 1
		new_subscription_status = 0
		period_end = Time.now + 1.month

		torera = users(:torera)
		torera.plan = old_plan
		torera.subscription_status = old_subscription_status
		torera.period_end = period_end

		# Create the event
		event = StripeMock.mock_webhook_event('customer.subscription.deleted')
		event.data.object.customer = torera.stripe_customer_id

		# Trigger the event
		StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)
		
		# The user should now have a free plan with no period_end and active_subscription_status
		torera = User.find_by_id(torera.id)
		assert_equal(new_plan, torera.plan)
		assert_equal(new_subscription_status, torera.subscription_status)
		assert_nil(torera.period_end)
	end
   # End CustomerSubscriptionDeletedEvent tests
end