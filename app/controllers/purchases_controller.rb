class PurchasesController < ApplicationController
	def create_purchase
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])
		object_id = params[:id]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt, session_id)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			object = TableObject.find_by_uuid(object_id)
			object = TableObject.find_by_id(object_id) if !object
			ValidationService.raise_validation_error(ValidationService.validate_table_object_does_not_exist(object))

			# Check if the user of the table object exists
			provider_user = object.user
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(provider_user))

			# Check if the app of the table object belongs to the dev
			ValidationService.raise_validation_error(ValidationService.validate_app_belongs_to_dev(object.table.app, dev))

			# Check if the user already purchased the table object
			ValidationService.raise_validation_error(ValidationService.validate_table_object_already_purchased(user, object))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)
			price = body["price"]
			currency = body["currency"]
			product_image = body["product_image"]
			product_name = body["product_name"]
			provider_image = body["provider_image"]
			provider_name = body["provider_name"]

			# Validate the properties
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_price_missing(price),
				ValidationService.validate_currency_missing(currency),
				ValidationService.validate_product_image_missing(product_image),
				ValidationService.validate_product_name_missing(product_name),
				ValidationService.validate_provider_image_missing(provider_image),
				ValidationService.validate_provider_name_missing(provider_name)
			])

			# Check if the price is valid
			ValidationService.raise_validation_error(ValidationService.validate_price_not_valid(price))

			# Check if the currency is supported
			ValidationService.raise_validation_error(ValidationService.validate_currency_supported(currency))

			# If the object belongs to the user, set the price to 0
			price = 0 if object.user == user

			if price > 0
				# Check if the user of the table object is a provider
				ValidationService.raise_validation_error(ValidationService.validate_user_of_table_object_is_provider(object))
			end

			# Check for too short or too long params
			ValidationService.raise_multiple_validation_errors([
				ValidationService.validate_product_image_too_short(product_image),
				ValidationService.validate_product_image_too_long(product_image),
				ValidationService.validate_product_name_too_short(product_name),
				ValidationService.validate_product_name_too_long(product_name),
				ValidationService.validate_provider_image_too_short(provider_image),
				ValidationService.validate_provider_image_too_long(provider_image),
				ValidationService.validate_provider_name_too_short(provider_name),
				ValidationService.validate_provider_name_too_long(provider_name)
			])

			# Create the purchase
			purchase = Purchase.new(
				user: user,
				table_object: object,
				product_image: product_image,
				product_name: product_name,
				provider_image: provider_image,
				provider_name: provider_name,
				price: price,
				currency: currency
			)

			if price > 0
				# Create a Stripe Customer for the user if there is none
				if !user.stripe_customer_id
					customer = Stripe::Customer.create(email: user.email)
					user.stripe_customer_id = customer.id
					ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user.save))
				end

				# Create a Stripe PaymentIntent
				payment_intent = Stripe::PaymentIntent.create({
					customer: user.stripe_customer_id,
					amount: price,
					currency: currency,
					confirmation_method: 'manual',
					application_fee_amount: (price * 0.2).round,
					transfer_data: {
						destination: object.user.provider.stripe_account_id
					}
				})

				purchase.payment_intent_id = payment_intent.id
			else
				purchase.completed = true
			end

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(purchase.save))

			# Return the data
			render json: purchase, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_purchase
		auth = request.headers['HTTP_AUTHORIZATION'] ? request.headers['HTTP_AUTHORIZATION'] : nil
		purchase_id = params[:id]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get the purchase
			purchase = Purchase.find_by_id(purchase_id)
			ValidationService.raise_validation_error(ValidationService.validate_purchase_does_not_exist(purchase))

			# Return the result
			render json: purchase.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def complete_purchase
		auth = request.headers['HTTP_AUTHORIZATION'] ? request.headers['HTTP_AUTHORIZATION'] : nil
		purchase_id = params[:id]

		begin
			ValidationService.raise_validation_error(ValidationService.validate_auth_missing(auth))
			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))

			api_key = auth.split(",")[0]
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get the purchase
			purchase = Purchase.find_by_id(purchase_id)
			ValidationService.raise_validation_error(ValidationService.validate_purchase_does_not_exist(purchase))

			# Check if the purchase is already completed
			ValidationService.raise_validation_error(ValidationService.validate_purchase_already_completed(purchase))
			
			# Check if the user already purchased the table object
			ValidationService.raise_validation_error(ValidationService.validate_table_object_already_purchased(purchase.user, purchase.table_object))

			# Check if the user has a stripe customer
			ValidationService.raise_validation_error(ValidationService.validate_user_is_stripe_customer(purchase.user))

			# Get the payment method of the user
			customer = Stripe::Customer.retrieve(purchase.user.stripe_customer_id)

			payment_methods = Stripe::PaymentMethod.list({
				customer: purchase.user.stripe_customer_id,
				type: 'card',
			})
			
			ValidationService.raise_validation_error(ValidationService.validate_user_has_payment_method(payment_methods))

			# Confirm the payment intent
			Stripe::PaymentIntent.confirm(
				purchase.payment_intent_id,
				{
					payment_method: payment_methods.data[0].id
				}
			)

			# Update the purchase with completed = true
			purchase.completed = true
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(purchase.save))

			# Return the purchase
			render json: purchase.attributes, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
end