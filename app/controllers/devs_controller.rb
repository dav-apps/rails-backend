class DevsController < ApplicationController
   def create_dev
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

         user_dev = Dev.find_by(user_id: user.id)
         ValidationService.raise_validation_error(ValidationService.validate_dev_already_exists(user_dev))
         
         user_dev = Dev.new(user_id: user.id)
         ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user_dev.save))

         result = user_dev
         render json: result, status: 201
      rescue RuntimeError => e
         validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
      end
   end

   def get_dev
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

         # Return the dev object
         result = user.dev.attributes

         apps_array = Array.new
         user.dev.apps.each { |app| apps_array.push(app) }

         result["apps"] = apps_array
         render json: result, status: 200
      rescue RuntimeError => e
         validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
      end
   end

   def get_dev_by_api_key
      auth = request.headers['HTTP_AUTHORIZATION'] ? request.headers['HTTP_AUTHORIZATION'] : nil
      requested_dev_api_key = params["api_key"]

      begin
         auth_validation = ValidationService.validate_auth_missing(auth)
         api_key_validation = ValidationService.validate_api_key_missing(requested_dev_api_key)
         errors = Array.new

         errors.push(auth_validation) if !auth_validation[:success]
         errors.push(api_key_validation) if !api_key_validation[:success]

         if errors.length > 0
				raise RuntimeError, errors.to_json
			end
			
			api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
         
			dev = Dev.find_by(api_key: api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(dev))

			ValidationService.raise_validation_error(ValidationService.validate_authorization(auth))
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			requested_dev = Dev.find_by(api_key: requested_dev_api_key)
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(requested_dev))

			# Return the data
			result = requested_dev.attributes
			
			apps_array = Array.new
			requested_dev.apps.each { |app| apps_array.push(app) }

			result["apps"] = apps_array
			render json: result, status: 200
      rescue RuntimeError => e
         validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
      end
	end
	
	def delete_dev
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
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(user.dev))
			
			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))
			ValidationService.raise_validation_error(ValidationService.validate_all_apps_deleted(user.dev))

			user.dev.destroy!
			result = {}
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def generate_new_keys
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
			ValidationService.raise_validation_error(ValidationService.validate_dev_does_not_exist(user.dev))

			ValidationService.raise_validation_error(ValidationService.validate_dev_is_first_dev(dev))

			# Generate new keys
			user_dev = user.dev
			user_dev.uuid = SecureRandom.uuid
			user_dev.api_key = SecureRandom.urlsafe_base64(30)
			user_dev.secret_key = SecureRandom.urlsafe_base64(40)

			ValidationService.raise_validation_error(ValidationService.validate_unknown_validation_error(user_dev.save))
			result = user_dev
			render json: result, status: 200
		rescue RuntimeError => e
			validations = JSON.parse(e.message)
			result = Hash.new
			result["errors"] = ValidationService.get_errors_of_validations(validations)

			render json: result, status: validations.last["status"]
		end
	end

	def tasks
		TasksWorker.perform_async
		render json: {}, status: 200
	end
end