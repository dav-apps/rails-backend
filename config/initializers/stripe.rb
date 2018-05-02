Rails.configuration.stripe = {
	:publishable_key => ENV['STRIPE_PUBLISHABLE_KEY'],
	:secret_key      => ENV['STRIPE_SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
StripeEvent.signing_secret = ENV['STRIPE_SIGNING_SECRET']


StripeEvent.configure do |events|
	events.subscribe 'invoice.payment_succeeded' do |event|
		# Find the user by the customer id
		customer_id = event.data.object.customer
		user = User.find_by(stripe_customer_id: customer_id)

		if user
			# Get the plan of the invoice
			# Update the user with new period_end and plan value
			period_end = event.data.object.period_end
			product_id = event.data.object.lines.data[0].plan.product

			user.period_end = Time.at(period_end) + 2.days

			if product_id == ENV['STRIPE_DAV_PLUS_PRODUCT_ID']
				user.plan = 1
			else
				user.plan = 0
			end

			user.save
		end

		200
	end

	events.all do |event|
		200
	end
end