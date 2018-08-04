class DevsController < ApplicationController
   
   def create_dev
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

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
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

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
      requested_dev_api_key = params["api_key"]
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

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

   define_method :delete_dev do
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
      end
      
      if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end
         
         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev || !user.dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Make sure this is called from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     # Check if the dev still has apps left
                     if user.dev.apps.length != 0
                        errors.push(Array.new([1107, "All Apps need to be deleted"]))
                        status = 400
                     else
                        # Delete dev
                        user.dev.destroy!
                        @result = {}
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :generate_new_keys do
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || jwt.length < 1
         errors.push(Array.new([2102, "Missing field: jwt"]))
         status = 401
      end
      
      if errors.length == 0
         jwt_valid = false
         begin
            decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
            jwt_valid = true
         rescue JWT::ExpiredSignature
            # JWT expired
            errors.push(Array.new([1301, "JWT: expired"]))
            status = 401
         rescue JWT::DecodeError
            errors.push(Array.new([1302, "JWT: not valid"]))
            status = 401
            # rescue other errors
         rescue Exception
            errors.push(Array.new([1303, "JWT: unknown error"]))
            status = 401
         end
         
         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev || !user.dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Make sure this is called from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     # Generate new keys
                     user_dev = user.dev
                     user_dev.uuid = SecureRandom.uuid
                     user_dev.api_key = SecureRandom.urlsafe_base64(30)
                     user_dev.secret_key = SecureRandom.urlsafe_base64(40)
                     
                     if !user_dev.save
                        errors.push(Array.new([1103, "Unknown validation error"]))
                        status = 500
                     else
                        @result = user_dev
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
end