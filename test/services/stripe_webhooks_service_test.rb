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
   test "InvoicePaymentSucceededEvent will update period_end and plan fields of user" do
      event = StripeMock.mock_webhook_event('invoice.payment_succeeded')
      torera = users(:torera)
      event.data.object.customer = torera.stripe_customer_id
      event.data.object.lines.data[0].plan.product = ENV['STRIPE_DAV_PLUS_PRODUCT_ID']

      period_end = torera.period_end
      plan = torera.plan

      StripeWebhooksService.InvoicePaymentSucceededEvent(event)

      torera = User.find_by_id(torera.id)
      assert_same(1, torera.plan)
      assert(torera.period_end != period_end)
   end
   # end InvoicePaymentSucceededEvent tests

   # InvoicePaymentFailedEvent tests
   test "InvoicePaymentFailedEvent will set the plan to free" do
      torera = users(:torera)
      torera.plan = 1
      torera.save

      event = StripeMock.mock_webhook_event('invoice.payment_failed')
      event.data.object.next_payment_attempt = nil
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.InvoicePaymentFailedEvent(event)

      # Check if the plan was updated
      torera = User.find_by_id(torera.id)
      assert_same(torera.plan, 0)
   end

   test "InvoicePaymentFailedEvent will not change the plan when paid is true of next_payment_attempt is not null" do
      torera = users(:torera)
      torera.plan = 1
      torera.save

      event = StripeMock.mock_webhook_event('invoice.payment_failed')
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.InvoicePaymentFailedEvent(event)

      # Get the updated user
      torera = User.find_by_id(torera.id)
      assert_same(1, torera.plan)

      event.data.object.paid = true
      event.data.object.next_payment_attempt = nil

      StripeWebhooksService.InvoicePaymentFailedEvent(event)

      # Get the updated user
      torera = User.find_by_id(torera.id)
      assert_same(torera.plan, 1)
   end
   # End InvoicePaymentFailedEvent tests

   # CustomerSubscriptionUpdatedEvent tests
   test "Cancelling the subscription in CustomerSubscriptionUpdatedEvent will update active plus plan to ending plus plan" do
      # Get user object with active plus subscription
      torera = users(:torera)
      torera.plan = 1
      torera.period_end = 11111
      torera.subscription_status = 0
      torera.save

      old_period_end = torera.period_end
      old_subscription_status = torera.subscription_status

      # Create event of cancelled subscription
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = true
      event.data.object.current_period_end = 123
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # User object will now have an ending plus subscription
      torera = User.find_by_id(torera.id)

      assert(old_period_end != torera.period_end)
      assert(old_subscription_status != torera.subscription_status)
   end

   test "Reactivating the subscription in CustomerSubscriptionUpdatedEvent will update ending plus plan to active plus plan" do
      # Get user object with ending plus subscription
      torera = users(:torera)
      torera.plan = 1
      torera.subscription_status = 1
      torera.save

      old_period_end = torera.period_end
      old_subscription_status = torera.subscription_status

      # Create event of reactivated subscription
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = 123
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # User will now have an active plus subscription
      torera = User.find_by_id(torera.id)
      assert(old_subscription_status != torera.subscription_status)
      assert(old_period_end != torera.period_end)
   end

   test "Updating the subscription in CustomerSubscriptionUpdatedEvent will update only the period_end" do
      # Get user object with active plus subscription
      torera = users(:torera)
      torera.plan = 1
      torera.subscription_status = 0
      torera.save

      old_period_end = torera.period_end
      old_subscription_status = torera.subscription_status

      # Create event of active subscription
      event = StripeMock.mock_webhook_event('customer.subscription.updated')
      event.data.object.cancel_at_period_end = false
      event.data.object.current_period_end = 123
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)

      # User will still have active subscription, but updated period_end
      torera = User.find_by_id(torera.id)
      assert_same(old_subscription_status, torera.subscription_status)
      assert(old_period_end != torera.period_end)
   end
   # End CustomerSubscriptionUpdatedEvent tests

   # CustomerSubscriptionDeletedEvent tests
   test "Deleting the subscription in CustomerSubscriptionDeletedEvent will update active plus plan to active free plan" do
      # Get user object with active plus subscription
      torera = users(:torera)
      torera.plan = 1
      torera.period_end = 11111
      torera.subscription_status = 0
      torera.save

      # Create event of active subscription
      event = StripeMock.mock_webhook_event('customer.subscription.deleted')
      event.data.object.current_period_end = 123
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)

      # User will have an active free plan
      torera = User.find_by_id(torera.id)
      assert_nil(torera.period_end)
      assert_same(torera.subscription_status, 0)
      assert_same(torera.plan, 0)
   end
   
   test "Deleting the subscription in CustomerSubscriptionDeletedEvent will update ending plus plan to active free plan" do
      # Get user object with ending plus subscription
      torera = users(:torera)
      torera.plan = 1
      torera.period_end = 11111
      torera.subscription_status = 1
      torera.save

      old_subscription_status = torera.subscription_status

      # Create event of active subscription
      event = StripeMock.mock_webhook_event('customer.subscription.deleted')
      event.data.object.current_period_end = 123
      event.data.object.customer = torera.stripe_customer_id

      StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)

      # User will have an active free plan
      torera = User.find_by_id(torera.id)
      assert_nil(torera.period_end)
      assert_same(torera.subscription_status, 0)
      assert_same(torera.plan, 0)
   end
   # End CustomerSubscriptionDeletedEvent tests
end