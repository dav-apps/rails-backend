class StripeWebhooksService

   def self.InvoicePaymentSucceededEvent(event)
      # Find the user by the customer id
      customer_id = event.data.object.customer
      user = User.find_by(stripe_customer_id: customer_id)

      if user
         # Get the plan of the invoice
         # Update the user with new period_end and plan value
         period_end = event.data.object.period_end
         product_id = event.data.object.lines.data[0].plan.product

         user.period_end = Time.at(period_end)
         
         if product_id == ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
            user.plan = 1
         else
            user.plan = 0
         end
         
         user.save
      end

      200
   end

   def self.InvoicePaymentFailedEvent(event)
      # With the second unsuccessful attempt to charge the customer, set the plan to 0 and send the email
      paid = event.data.object.paid
      next_payment_attempt = event.data.object.next_payment_attempt

      if !paid && !next_payment_attempt
         # Change plan to free
         customer_id = event.data.object.customer
         user = User.find_by(stripe_customer_id: customer_id)

         if user
            user.plan = 0
            user.save

            # Send the email
            UserNotifier.send_failed_payment_email(user).deliver_later
         end
      end

      200
   end
end