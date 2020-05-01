class ProvidersController < ApplicationController
	def create_provider
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))
			ValidationService.raise_validation_error(ValidationService.validate_content_type_json(request.headers["Content-Type"]))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]
			
			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Get the properties from the body
			body = ValidationService.parse_json(request.body.string)
			country = body["country"]

			# Make sure the country is present
			ValidationService.raise_validation_error(ValidationService.validate_country_missing(country))

			# Make sure the country is supported
			ValidationService.raise_validation_error(ValidationService.validate_country_supported(country))

			# Check if the user already has a provider
			ValidationService.raise_validation_error(ValidationService.validate_provider_already_exists(user.provider))

			# Create the stripe account
			account = Stripe::Account.create({
				type: 'custom',
				requested_capabilities: [
					'card_payments',
					'transfers'
				],
				business_type: 'individual',
				email: user.email,
				country: country,
				settings: {
					payouts: {
						schedule: {
							interval: "monthly",
							monthly_anchor: 13
						}
					}
				}
			})

			# Create the provider
			provider = Provider.new(id: user.id, user: user, stripe_account_id: account.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(provider.save))

			# Return the provider
			render json: {id: provider.id, user_id: provider.user_id, stripe_account_id: provider.stripe_account_id}, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end

	def get_provider
		jwt, session_id = get_jwt_from_header(request.headers['HTTP_AUTHORIZATION'])

		begin
			ValidationService.raise_validation_error(ValidationService.validate_jwt_missing(jwt))

			jwt_signature_validation = ValidationService.validate_jwt_signature(jwt)
			ValidationService.raise_validation_error(jwt_signature_validation[0])
			user_id = jwt_signature_validation[1][0]["user_id"]
			dev_id = jwt_signature_validation[1][0]["dev_id"]

			user = User.find_by_id(user_id)
			ValidationService.raise_validation_error(ValidationService.validate_user_does_not_exist(user))

			dev = Dev.find_by_id(dev_id)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Check if the provider exists
			provider = user.provider
			ValidationService.raise_validation_error(ValidationService.validate_provider_does_not_exist(provider))

			# Return the result
			render json: {id: provider.id, user_id: provider.user_id, stripe_account_id: provider.stripe_account_id}, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
end