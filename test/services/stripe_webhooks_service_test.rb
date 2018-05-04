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
      assert_same(0, torera.plan)
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
      assert_same(1, torera.plan)
   end
   # End InvoicePaymentFailedEvent tests
end