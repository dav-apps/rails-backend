Rails.configuration.stripe = {
	:publishable_key => ENV['STRIPE_PUBLISHABLE_KEY'],
	:secret_key      => ENV['STRIPE_SECRET_KEY']
}

Stripe.api_key = Rails.configuration.stripe[:secret_key]
StripeEvent.signing_secret = ENV['STRIPE_SIGNING_SECRET']


StripeEvent.configure do |events|
	events.subscribe 'invoice.payment_succeeded' do |event|
		StripeWebhooksService.InvoicePaymentSucceededEvent(event)
	end

	events.subscribe 'invoice.payment_failed' do |event|
		StripeWebhooksService.InvoicePaymentFailedEvent(event)
	end

	events.subscribe 'customer.subscription.created' do |event|
		StripeWebhooksService.CustomerSubscriptionCreatedEvent(event)
	end

	events.subscribe 'customer.subscription.updated' do |event|
		StripeWebhooksService.CustomerSubscriptionUpdatedEvent(event)
	end

	events.subscribe 'customer.subscription.deleted' do |event|
		StripeWebhooksService.CustomerSubscriptionDeletedEvent(event)
	end
end