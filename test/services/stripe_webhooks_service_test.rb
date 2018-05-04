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
   test "InvoicePaymentSucceededEvent will update period_end field of user" do
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
end