class UsersController < ApplicationController
    require 'jwt'
    minUsernameLength = 3
    maxUsernameLength = 25
    minPasswordLength = 7
    
    define_method :signup do
        email = params[:email]
        password = params[:password]
        username = params[:username]
        
        errors = Array.new
        @result = Hash.new
        
        @user = User.new(email: email, password: password, username: username)
        
        if !email || !password || !username || email.length < 2 || password.length < 2 || username.length < 2
            errors.push(Array.new([1, "Email, password or username is null"]))
        else
            # If password, username and email exist
            
            if !validate_email(email)
                errors.push(Array.new([2, "Email is not valid"]))
            end
            
            if password.length <= minPasswordLength
                errors.push(Array.new([3, "Password is too short"]))
            end
            
            if username.length <= minUsernameLength
                errors.push(Array.new([4, "Username is too short"]))
            end
            
            if username.length > maxUsernameLength
                errors.push(Array.new([5, "Username is too long"]))
            end
            
            if User.exists?(email: email)
                errors.push(Array.new([6, "Email is already taken"]))
            end
            
            if User.exists?(username: username)
                errors.push(Array.new([7, "Username is already taken"]))
            end
        end
        
        @user.email_confirmation_token = generate_token
        
        if @user.save && errors.length == 0
            @result["signup"] = true
            UserNotifier.send_signup_email(@user).deliver_later
        else
            @user.errors.each do |e|
                if @user.errors[e].any?
                    @user.errors[e].each do |errorMessage|
                        errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                    end
                end
            end
            
            @result["signup"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
   def login
      email = params[:email]
      password = params[:password]
        
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      result = Hash.new
      ok = false
        
      if !email || email.length < 1
         errors.push(Array.new([0000, "Missing field: email"]))
         status = 400
      end
        
      if !password || password.length < 1
         errors.push(Array.new([0000, "Missing field: password"]))
         status = 400
      end
      
      if !auth || auth.length < 1
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
        
      if errors.length == 0
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([0000, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(api_key, sig)
               errors.push(Array.new([0000, "Authentication failed"]))
               status = 401
            else
               user = User.find_by(email: email)
               
               if !user
                  errors.push(Array.new([0000, "Resource does not exist: User"]))
                  status = 400
               else
                  if !user.authenticate(password)
                     errors.push(Array.new([0000, "Password is incorrect"]))
                     status = 401
                  else
                     if !user.confirmed
                        errors.push(Array.new([0000, "User is not confirmed"]))
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
         expHours = 6
         exp = Time.now.to_i + expHours * 3600
         payload = {:email => user.email, :username => user.username, :user_id => user.id, :dev_id => dev.id, :exp => exp}
         token = JWT.encode payload, ENV['JWT_SECRET'], ENV['JWT_ALGORITHM']
         result["jwt"] = token
         
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
    
    define_method :set_username do
        new_username = params["new_username"]
        jwt = request.headers['HTTP_AUTHORIZATION']
        
        errors = Array.new
        @result = Hash.new
        ok = false
        
        if !new_username || !jwt || new_username.length < 1 || jwt.length < 2
            errors.push(Array.new([1, "New username or JWT is null"]))
        else
            jwt_valid = false
            begin
                decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
                jwt_valid = true
            rescue JWT::ExpiredSignature
                # JWT expired
                errors.push(Array.new([2, "The JWT is expired"]))
            rescue JWT::DecodeError
                errors.push(Array.new([3, "The JWT is not valid"]))
                # rescue other errors
            rescue Exception
                errors.push(Array.new([4, "There was an error with your JWT"]))
            end
            
            if new_username.length <= minUsernameLength
                errors.push(Array.new([5, "Username is too short"]))
            end
            
            if new_username.length > maxUsernameLength
                errors.push(Array.new([6, "Username is too long"]))
            end
            
            if jwt_valid
                @user = User.find_by_id(decoded_jwt[0]["id"])
                
                if !@user
                    errors.push(Array.new([7, "This user does not exist"]))
                else
                    @user.username = new_username
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def change_email
        new_email = params["new_email"]
        jwt = request.headers['HTTP_AUTHORIZATION']
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !new_email || !jwt || new_email.length < 2
            errors.push(Array.new([1, "New email or JWT is null"]))
        else
            jwt_valid = false
            begin
                decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
                jwt_valid = true
            rescue JWT::ExpiredSignature
                # JWT expired
                errors.push(Array.new([2, "The JWT is expired"]))
            rescue JWT::DecodeError
                errors.push(Array.new([3, "The JWT is not valid"]))
                # rescue other errors
            rescue Exception
                errors.push(Array.new([4, "There was an error with your JWT"]))
            end
            
            if !validate_email(new_email)
                errors.push(Array.new([5, "The email is not valid"]))
            end
            
            if jwt_valid
                @user = User.find_by_id(decoded_jwt[0]["id"])
                
                if !@user
                    errors.push(Array.new([6, "This user does not exist"]))
                else
                    @user.old_email = @user.email
                    @user.new_email = new_email
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
            
            @user.email_confirmation_token = generate_token
            @user.save
            
            # Send email
            UserNotifier.send_change_email_email(@user).deliver_later
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    define_method :change_password do
        # This method is to change the password from within the account in the settings, JWT required
        new_password = params["new_password"]
        jwt = request.headers['HTTP_AUTHORIZATION']
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !jwt || !new_password || jwt.length < 2 || new_password.length < 2
            errors.push(Array.new([1, "JWT or new_password is null"]))
        else
            jwt_valid = false
            begin
                decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
                jwt_valid = true
            rescue JWT::ExpiredSignature
                # JWT expired
                errors.push(Array.new([2, "The JWT is expired"]))
            rescue JWT::DecodeError
                errors.push(Array.new([3, "The JWT is not valid"]))
            rescue Exception
                # rescue other errors
                errors.push(Array.new([4, "There was an error with your JWT"]))
            end
            
            @user = User.find_by_id(decoded_jwt[0]["id"])
            if !@user
                errors.push(Array.new([5, "This user does not exist"]))
            else
                if new_password.length <= minPasswordLength
                    errors.push(Array.new([6, "The password is too short"]))
                end
                puts new_password.length <= minPasswordLength
                @user.new_password = new_password
                @user.password_confirmation_token = generate_token
                
                if @user.save && errors.length == 0
                    ok = true
                else
                    @user.errors.each do |e|
                        if @user.errors[e].any?
                            @user.errors[e].each do |errorMessage|
                                errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
            
            # Send email
            UserNotifier.send_change_password_email(@user).deliver_later
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def set_avatar_file_extension
        ext = params["ext"]
        jwt = request.headers['HTTP_AUTHORIZATION']
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !jwt || !ext || jwt.length < 2 || ext.length < 3
            errors.push(Array.new([1, "JWT or ext is null"]))
        else
            jwt_valid = false
            begin
                decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
                jwt_valid = true
            rescue JWT::ExpiredSignature
                # JWT expired
                errors.push(Array.new([2, "The JWT is expired"]))
            rescue JWT::DecodeError
                errors.push(Array.new([3, "The JWT is not valid"]))
            rescue Exception
                # rescue other errors
                errors.push(Array.new([4, "There was an error with your JWT"]))
            end
            
            if jwt_valid
                @user = User.find_by_id(decoded_jwt[0]["id"])
                
                if !@user
                    errors.push(Array.new([5, "This user does not exist"]))
                else
                    @user.avatar_file_extension = ext
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    # Dev routes
    def confirm_user
        id = params[:id]
        confirmation_token = params[:confirmation_token]
        
        errors = Array.new
        @result = Hash.new
        
        confirmed = false
        
        if !id || !confirmation_token || id.length < 1
            errors.push(Array.new([1, "ID or confirmation_token is null"]))
        else
            @user = User.find_by_id(id)
            
            if !@user
                errors.push(Array.new([2, "This user does not exist"]))
            else
                if @user.confirmed
                    errors.push(Array.new([3, "Your account is already confirmed"]))
                elsif @user.email_confirmation_token == confirmation_token
                    # Confirm user
                    @user.confirmed = true
                    if @user.save && errors.length == 0
                        confirmed = true
                        @user.email_confirmation_token = nil
                        @user.save
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                else
                    errors.push(Array.new([4, "The confirmation token is not correct"]))
                end
            end
        end
        
        if confirmed
            @result["confirmed"] = true
        else
            @result["confirmed"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def send_verification_email
        email = params[:email]
        @user = User.find_by_email(email)
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !email || email.length < 2
            errors.push(Array.new([1, "Email is null"]))
        else
            if !@user
                errors.push(Array.new([2, "A user with that email does not exist"]))
            else
                if @user.confirmed
                    errors.push(Array.new([3, "Your account is already confirmed"]))
                else
                    # Generate email_confirmation_token and save in DB
                    @user.email_confirmation_token = generate_token
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["sent"] = true
            UserNotifier.send_signup_email(@user).deliver_later
        else
            @result["sent"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def send_password_reset_email
        email = params["email"]
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !email || email.length < 2
            errors.push(Array.new([1, "Email is null"]))
        else
            @user = User.find_by_email(email)
            
            if !@user
                errors.push(Array.new([2, "A user with that email does not exist"]))
            else
                # Generate password_confirmation_token and safe in DB
                @user.password_confirmation_token = generate_token
                if @user.save && errors.length == 0
                    ok = true
                else
                    @user.errors.each do |e|
                        if @user.errors[e].any?
                            @user.errors[e].each do |errorMessage|
                                errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["sent"] = true
            
            # Send email
            UserNotifier.send_password_reset_email(@user).deliver_later
        else
            @result["sent"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def check_password_confirmation_token
        id = params["id"]
        password_confirmation_token = params['confirmation_token']
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !id || !password_confirmation_token || id.length < 1 || password_confirmation_token.length < 2
            errors.push(Array.new([1, "ID or confirmation token is null"]))
        else
            @user = User.find_by_id(id)
            
            if !@user
                errors.push(Array.new([2, "This user does not exist"]))
            else
                if @user.password_confirmation_token != password_confirmation_token
                    errors.push(Array.new([3, "The confirmation token is not correct"]))
                else
                    ok = true
                end
            end
        end
        
        if ok
            @result["checked"] = true
        else
            @result["checked"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    define_method :save_new_password do
        # This method is to reset the password from outside of the account, no JWT required
        id = params["id"]
        confirmation_token = params["confirmation_token"]
        new_password = params["new_password"]
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !id || !confirmation_token || !new_password || id.length < 1 || confirmation_token.length < 2 || new_password.length < 2
            errors.push(Array.new([1, "ID, confirmation_token or new password is null"]))
        else
            if new_password.length <= minPasswordLength
                errors.push(Array.new([2, "The password is too short"]))
            end
            
            @user = User.find_by_id(id)
            if !@user
                errors.push(Array.new([3, "This user does not exist"]))
            else
                if @user.password_confirmation_token != confirmation_token
                    errors.push(Array.new([4, "The confirmation token is not correct"]))
                else
                    @user.password = new_password
                    
                    if @user.save && errors.length == 0
                        ok = true
                        @user.password_confirmation_token = nil
                        @user.save
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def confirm_new_password
        # Check if password confirmation token is correct and update DB with new password and nil token
        id = params["id"]
        confirmation_token = params["confirmation_token"]
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !id || !confirmation_token || confirmation_token.length < 2
            errors.push(Array.new([1, "ID or confirmation token is null"]))
        else
            @user = User.find_by_id(id)
            
            if !@user
                errors.push(Array.new([2, "This user does not exist"]))
            else
                if @user.password_confirmation_token != confirmation_token
                    errors.push(Array.new([3, "The confirmation token is not correct"]))
                else
                    @user.password_confirmation_token = nil
                    # Save new email
                    @user.password = @user.new_password
                    @user.new_password = nil
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def confirm_new_email
        # Save new email and send an email to old_email with reset link which says that email has changed
        id = params["id"]
        confirmation_token = params["confirmation_token"]
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !id || !confirmation_token || confirmation_token.length < 2
            errors.push(Array.new([1, "ID or confirmation token is null"]))
        else
            @user = User.find_by_id(id)
            
            if !@user
                errors.push(Array.new([2, "This user does not exist"]))
            else
                if @user.email_confirmation_token != confirmation_token
                    errors.push(Array.new([3, "The confirmation token is not correct"]))
                else
                    @user.email_confirmation_token = nil
                    # Save new email
                    @user.email = @user.new_email
                    @user.new_email = nil
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
            # Send reset_new_email email
            UserNotifier.send_reset_new_email_email(@user).deliver_later
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def reset_new_email
        # Save old_email as email and save new_email as null
        id = params["id"]
        ok = false
        
        errors = Array.new
        @result = Hash.new
        
        if !id
            errors.push(Array.new([1, "ID is null"]))
        else
            @user = User.find_by_id(id)
            
            if !@user
                errors.push(Array.new([2, "This user does not exist"]))
            else
                if !@user.old_email || !validate_email(@user.old_email)
                    errors.push(Array.new([3, "Your old email is null or not valid"]))
                else
                    @user.email = @user.old_email
                    @user.old_email = nil
                    
                    if @user.save && errors.length == 0
                        ok = true
                    else
                        @user.errors.each do |e|
                            if @user.errors[e].any?
                                @user.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                end
                            end
                        end
                    end
                end
            end
        end
        
        if ok
            @result["saved"] = true
        else
            @result["saved"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
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