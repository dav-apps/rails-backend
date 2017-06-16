class UsersController < ApplicationController
    require 'jwt'
    minUsernameLength = 2
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
            
            if User.exists?(email: email)
                errors.push(Array.new([5, "Email is already taken"]))
            end
            
            if User.exists?(username: username)
                errors.push(Array.new([6, "Username is already taken"]))
            end
        end
        
        @user.email_confirmation_token = generate_token
        
        if @user.save
            @result["signup"] = true
            UserNotifier.send_signup_email(@user).deliver_now
        else
            @user.errors.each do |e|
                errors.push(Array.new([0, e]))
            end
            
            @result["signup"] = false
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    def login
        email = params[:email]
        password = params[:password]
        
        errors = Array.new
        @result = Hash.new
        password_correct = false
        
        
        if !email || !password || email.length < 2 || password.length < 2
            errors.push(Array.new([1, "Email or password is null"]))
        else
            @user = User.find_by(email: email)
            
            if !@user
                errors.push(Array.new([2, "User with that email does not exist"]))
            else
                if !@user.confirmed
                    errors.push(Array.new([3, "Please confirm your email to be able to login"]))
                else
                    #if @user.password == password
                    if @user.authenticate(password)
                        password_correct = true
                    else
                        errors.push(Array.new([4, "The password is incorrect"]))
                        password_correct = false
                    end
                end
            end
        end
        
        @result["login"] = password_correct
        
        if password_correct
            # Create JWT and result
            payload = {:email => @user.email, :username => @user.username, :id => @user.id}
            token = JWT.encode payload, ENV['JWT_SECRET'], 'HS256'
            
            @result["jwt"] = token
            @result["user"] = @user
        else
            @result["errors"] = errors
        end
        
        @result = @result.to_json.html_safe
    end
    
    define_method :set_username do
        new_username = params["new_username"]
        jwt = params["jwt"]
        
        errors = Array.new
        @result = Hash.new
        ok = false
        
        if !new_username || !jwt || new_username.length < 1 || jwt.length < 2
            errors.push(Array.new([1, "New username or JWT is null"]))
        else
            jwt_valid = false
            begin
                decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => 'HS256' }
                jwt_valid = true
            rescue JWT::ExpiredSignature
                # JWT expired
                errors.push(Array.new([2, "The JWT is expired"]))
            rescue JWT::DecodeError
                errors.push(Array.new([3, "The JWT is not valid"]))
                # TODO rescue other errors
            end
            
            if new_username.length <= minUsernameLength
                errors.push(Array.new([4, "Username is too short"]))
            end
            
            if jwt_valid
                @user = User.find_by_id(decoded_jwt[0]["id"])
                
                if !@user
                    errors.push(Array.new([5, "This user does not exist"]))
                else
                    @user.username = new_username
                    
                    if @user.save
                        ok = true
                    else
                        @user.errors.each do |e|
                            errors.push(Array.new([0, e]))
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
                    if @user.save
                        confirmed = true
                        @user.email_confirmation_token = nil
                        @user.save
                    else
                        @user.errors.each do |e|
                            errors.push(Array.new([0, e]))
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
                    if @user.save
                        ok = true
                        UserNotifier.send_signup_email(@user).deliver_now
                    else
                        @user.errors.each do |e|
                            errors.push(Array.new([0, e]))
                        end
                    end
                end
            end
        end
        
        if ok
            @result["sent"] = true
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
                if @user.save
                    ok = true
                    # Send email
                    UserNotifier.send_password_reset_email(@user).deliver_now
                else
                    @user.errors.each do |e|
                        errors.push(Array.new([0, e]))
                    end
                end
            end
        end
        
        if ok
            @result["sent"] = true
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
                    
                    if @user.save
                        ok = true
                        @user.password_confirmation_token = nil
                        @user.save
                    else
                        @user.errors.each do |e|
                            errors.push(Array.new([0, e]))
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