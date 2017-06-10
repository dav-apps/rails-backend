class UsersController < ApplicationController
    
    def signup
        minUsernameLength = 2
        minPasswordLength = 7
        
        email = params[:email]
        password = params[:password]
        username = params[:username]
        
        errors = Array.new
        @result = Hash.new
        
        @user = User.new(email: email, password: password, username: username)
        
        if !email || !password || !username
            errors.push(Array.new(["1", "Email, password or username is null"]))
        else
            # If password, username and email exist
            
            if !validate_email(email)
                errors.push(Array.new(["2", "Email is not valid"]))
            end
            
            if password.length <= minPasswordLength
                errors.push(Array.new(["3", "Password is too short"]))
            end
            
            if username.length <= minUsernameLength
                errors.push(Array.new(["4", "Username is too short"]))
            end
            
            if User.exists?(email: email)
                errors.push(Array.new(["5", "Email is already taken"]))
            end
            
            if User.exists?(username: username)
                errors.push(Array.new(["6", "Username is already taken"]))
            end
        end
        
        @user.email_confirmation_token = generate_token
        
        if @user.save
            @result["signup"] = "true"
            @result["errorCode"] = "0"
            UserNotifier.send_signup_email(@user).deliver
        else
            @result["signup"] = "false"
            @result["errors"] = errors
        end
        
        @result = @result.to_json
    end
    
    def login
        
    end
    
    private
    def send_verification_email
        
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