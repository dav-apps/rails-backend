class UsersController < ApplicationController
    require 'jwt'
    
    def signup
        minUsernameLength = 2
        minPasswordLength = 7
        
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
                        @user.save!
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
    
    
    private
    def generate_token
        SecureRandom.hex(20)
    end
    
    def validate_email(email)
        reg = Regexp.new("[a-z0-9!#$%&'*+/=?^_`{|}~-]+(?:\.[a-z0-9!#$%&'*+/=?^_`{|}~-]+)*@(?:[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?")
        return (reg.match(email))? true : false
    end
end