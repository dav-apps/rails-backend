class ProvidersController < ApplicationController
	def create_provider
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

			# Check if the user already has a provider
			ValidationService.raise_validation_error(ValidationService.validate_provider_already_exists(user.provider))

			# Create the stripe account
			account = Stripe::Account.create({
				type: 'custom',
				requested_capabilities: [
					'card_payments',
					'transfers'
				]
			})

			# Create the provider
			provider = Provider.new(user: user, stripe_account_id: account.id)
			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(provider.save))

			# Return the provider
			render json: {id: provider.id, user_id: provider.user_id, stripe_account_id: provider.stripe_account_id}, status: 201
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			render json: {"errors" => ValidationService.get_errors_of_validations(validations)}, status: validations.last["status"]
		end
	end
end