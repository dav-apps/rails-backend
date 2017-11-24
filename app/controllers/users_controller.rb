class UsersController < ApplicationController
   require 'jwt'
   min_username_length = 2
   max_username_length = 25
   min_password_length = 7
   max_password_length = 25
   
   define_method :signup do
      email = params[:email]
      password = params[:password]
      username = params[:username]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if !password || password.length < 1
         errors.push(Array.new([2107, "Missing field: password"]))
         status = 400
      end
      
      if !username || username.length < 1
         errors.push(Array.new([2105, "Missing field: username"]))
         status = 400
      end
      
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
                  if User.exists?(email: email)
                     errors.push(Array.new([2702, "Field already taken: email"]))
                     status = 400
                  else
                     # Validate the fields
                     if !validate_email(email)
                        errors.push(Array.new([2401, "Field not valid: email"]))
                        status = 400
                     end
                     
                     if password.length < min_password_length
                        errors.push(Array.new([2202, "Field too short: password"]))
                        status = 400
                     end
                     
                     if password.length > max_password_length
                        errors.push(Array.new([2302, "Field too long: password"]))
                        status = 400
                     end
                     
                     if username.length < min_username_length
                        errors.push(Array.new([2201, "Field too short: username"]))
                        status = 400
                     end
                     
                     if username.length > max_username_length
                        errors.push(Array.new([2301, "Field too long: username"]))
                        status = 400
                     end
                     
                     if User.exists?(username: username)
                        errors.push(Array.new([2701, "Field already taken: username"]))
                        status = 400
                     end
                     
                     if errors.length == 0
                        @user = User.new(email: email, password: password, username: username)
                        # Save the new user
                        @user.email_confirmation_token = generate_token
               
                        if !@user.save
                           errors.push(Array.new([1103, "Unknown validation error"]))
                           status = 500
                        else
                           UserNotifier.send_signup_email(@user).deliver_later
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
         @result = @user
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def login
      email = params[:email]
      password = params[:password]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if !password || password.length < 1
         errors.push(Array.new([2107, "Missing field: password"]))
         status = 400
      end
      
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
            user = User.find_by(email: email)
            
            if !user
               errors.push(Array.new([2801, "Resource does not exist: User"]))
               status = 400
            else
               if !check_authorization(api_key, sig)
                  errors.push(Array.new([1101, "Authentication failed"]))
                  status = 401
               else
                  if !user.authenticate(password)
                     errors.push(Array.new([1201, "Password is incorrect"]))
                     status = 401
                  else
                     if !user.confirmed
                        errors.push(Array.new([1202, "User is not confirmed"]))
                        status = 400
                     else
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         # Create JWT and result
         expHours = Rails.env.production? ? 6 : 10000000
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         @result["jwt"] = token
         @result["user_id"] = user.id
         
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_user
      requested_user_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !requested_user_id
         errors.push(Array.new([2104, "Missing field: user_id"]))
         status = 400
      end
      
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
                  requested_user = User.find_by_id(requested_user_id)
                  
                  if !requested_user
                     errors.push(Array.new([2801, "Resource does not exist: User"]))
                     status = 404
                  else
                     # Check if the logged in user is the requested user
                     if requested_user.id != user.id
                        errors.push(Array.new([1102, "Action not allowed"]))
                        status = 403
                     else
                        @result = requested_user.attributes.except("email_confirmation_token", "password_confirmation_token", "new_password")
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
   
   define_method :update_user do
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
                  # Check if the call was made from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     if request.headers["Content-Type"] != "application/json" && request.headers["Content-Type"] != "application/json; charset=utf-8"
                        errors.push(Array.new([1104, "Content-type not supported"]))
                        status = 415
                     else
                        email_changed = false
                        password_changed = false
                        object = request.request_parameters
                        
                        email = object["email"]
                        if email && email.length > 0
                           if !validate_email(email)
                              errors.push(Array.new([2401, "Field not valid: email"]))
                              status = 400
                           end
                           
                           if errors.length == 0
                              # Set email_confirmation_token and send email
                              user.new_email = email
                              user.email_confirmation_token = generate_token
                              email_changed = true
                           end
                        end
                        
                        username = object["username"]
                        if username && username.length > 0
                           if username.length < min_username_length
                              errors.push(Array.new([2201, "Field too short: username"]))
                              status = 400
                           end
                           
                           if username.length > max_username_length
                              errors.push(Array.new([2301, "Field too long: username"]))
                              status = 400
                           end
                           
                           if User.exists?(username: username)
                              errors.push(Array.new([2701, "Field already taken: username"]))
                              status = 400
                           end
                           
                           if errors.length == 0
                              user.username = username
                           end
                        end
                        
                        password = object["password"]
                        if password && password.length > 0
                           if password.length < min_password_length
                              errors.push(Array.new([2202, "Field too short: password"]))
                              status = 400
                           end
                           
                           if password.length > max_password_length
                              errors.push(Array.new([2302, "Field too long: password"]))
                              status = 400
                           end
                           
                           if errors.length == 0
                              # Set password_confirmation_token and send email
                              user.new_password = password
                              user.password_confirmation_token = generate_token
                              password_changed = true
                           end
                        end
                        
                        avatar_file_extension = object["avatar_file_extension"]
                        if avatar_file_extension && avatar_file_extension.length > 0
                           if errors.length == 0
                              user.avatar_file_extension = avatar_file_extension
                           end
                        end
                        
                        
                        if errors.length == 0
                           # Update user with new properties
                           if !user.save
                              errors.push(Array.new([1103, "Unknown validation error"]))
                              status = 500
                           else
                              @result = user.attributes.except("email_confirmation_token", "password_confirmation_token", "new_password")
                              ok = true
                              
                              if email_changed
                                 UserNotifier.send_change_email_email(user).deliver_later
                              end
                              
                              if password_changed
                                 UserNotifier.send_change_password_email(user).deliver_later
                              end
                           end
                        end
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
   
   def delete_user
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
                  # Check if the call was send from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     # Delete the user
                     user.destroy!
                     @result = {}
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
   
   def confirm_user
      email_confirmation_token = params["email_confirmation_token"]
      user_id = params["id"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email_confirmation_token || email_confirmation_token.length < 1
         errors.push(Array.new([2108, "Missing field: email_confirmation_token"]))
         status = 400
      end
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if user.confirmed == true
               errors.push(Array.new([1106, "User is already confirmed"]))
               status = 400
            else
               if user.email_confirmation_token != email_confirmation_token
                  errors.push(Array.new([1204, "Email confirmation token is not correct"]))
                  status = 400
               else
                  user.email_confirmation_token = nil
                  user.confirmed = true
                  user.save!
                  
                  ok = true
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
   
   def send_verification_email
      email = params["email"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by(email: email)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if user.confirmed == true
               errors.push(Array.new([1106, "User is already confirmed"]))
               status = 400
            else
               user.email_confirmation_token = generate_token
               if !user.save
                  errors.push(Array.new([1103, "Unknown validation error"]))
                  status = 500
               else
                  ok = true
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
         # Send email
         UserNotifier.send_signup_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def send_password_reset_email
      email = params["email"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !email || email.length < 1
         errors.push(Array.new([2106, "Missing field: email"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by(email: email)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            # Generate password confirmation token
            user.password_confirmation_token = generate_token
            if !user.save
               errors.push(Array.new([1103, "Unknown validation error"]))
               status = 500
            else
               ok = true
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
         # Send email
         UserNotifier.send_password_reset_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def save_new_password
      user_id = params["id"]
      password_confirmation_token = params["password_confirmation_token"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if !password_confirmation_token || password_confirmation_token.length < 1
         errors.push(Array.new([2109, "Missing field: password_confirmation_token"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if password_confirmation_token != user.password_confirmation_token
               errors.push(Array.new([1203, "Password confirmation token is not correct"]))
               status = 400
            else
               if user.new_password == nil || user.new_password.length < 1
                  errors.push(Array.new([2603, "Field is empty: new_password"]))
                  status = 400
               else
                  # Save new password
                  user.password = user.new_password
                  user.new_password = nil
                  
                  user.password_confirmation_token = nil
                  
                  if !user.save
                     errors.push(Array.new([1103, "Unknown validation error"]))
                     status = 500
                  else
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
   
   def save_new_email
      user_id = params["id"]
      email_confirmation_token = params["email_confirmation_token"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if !email_confirmation_token || email_confirmation_token.length < 1
         errors.push(Array.new([2108, "Missing field: email_confirmation_token"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if email_confirmation_token != user.email_confirmation_token
               errors.push(Array.new([1204, "Email confirmation token is not correct"]))
               status = 400
            else
               if user.new_email == nil || user.new_email.length < 1
                  errors.push(Array.new([2601, "Field is empty: new_email"]))
                  status = 400
               else
                  # Save new email
                  user.old_email = user.email
                  user.email = user.new_email
                  user.new_email = nil
                  
                  user.email_confirmation_token = nil
                  
                  if !user.save
                     errors.push(Array.new([1103, "Unknown validation error"]))
                     status = 500
                  else
                     ok = true
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 200
         UserNotifier.send_reset_new_email_email(user).deliver_later
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def reset_new_email
      # This method exists to reset the new email, when the email change was not intended by the account owner
      user_id = params["id"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !user_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if errors.length == 0
         user = User.find_by_id(user_id)
         
         if !user
            errors.push(Array.new([2801, "Resource does not exist: User"]))
            status = 400
         else
            if !user.old_email || user.old_email.length < 1
               errors.push(Array.new([2602, "Field is empty: old_email"]))
               status = 400
            else
               # set new_email to email and email to old_email
               user.email = user.old_email
               user.old_email = nil
               
               if !user.save
                  errors.push(Array.new([1103, "Unknown validation error"]))
                  status = 500
               else
                  ok = true
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
   
   private
   def generate_token
      SecureRandom.hex(20)
   end
    
   def validate_email(email)
      reg = Regexp.new("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
      return (reg.match(email))? true : false
   end
end