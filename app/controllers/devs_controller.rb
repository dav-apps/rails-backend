class DevsController < ApplicationController
   
   define_method :create_dev do
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
               
               if !dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Make sure this is only called from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     # Check if the user already is a dev
                     user_dev = Dev.find_by(user_id: user.id)
                     
                     if user_dev
                        errors.push(Array.new([2902, "Resource already exists: Dev"]))
                        status = 400
                     else
                        # Create new dev for the user
                        user_dev = Dev.new(user_id: user.id)
                        
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
      end
      
      if ok && errors.length == 0
         status = 201
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :get_dev do
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
                  status = 404
               else
                  # Make sure this is called from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     # Return the dev object
                     @result = user.dev
                     ok = true
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
   
   define_method :get_dev_by_api_key do
      requested_dev_api_key = params["api_key"]
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !auth || auth.length < 1
         errors.push(Array.new([2101, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([2802, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(api_key, sig)
               errors.push(Array.new([1101, "Authentication failed"]))
               status = 401
            else
               if dev.user_id != Dev.first.user_id
                  errors.push(Array.new([1102, "Action not allowed"]))
                  status = 403
               else
                  # Get requested dev
                  requested_dev = Dev.find_by(api_key: requested_dev_api_key)
                  
                  if !requested_dev
                     errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                     status = 400
                  else
                     @result = requested_dev
                     ok = true
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