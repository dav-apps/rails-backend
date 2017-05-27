class UsersController < ApplicationController
    
    def signup
        email = params[:email]
        password = params[:password]
        username = params[:username]
        
        error = ""
        errorCode = 0
        @result = Hash.new
        
        @user = User.new(email: email, password: password, username: username)
        
        if !email || !password || !username
            error = 'Email, password or username is null'
            errorCode = 1
        elsif password.length <= 7
            error = 'Password is too short'
            errorCode = 2
        end
        
        if @user.save
            @result["signup"] = "true"
            @result["errorCode"] = "0"
        else
        #    @result["signup"] = "false"
        #    @result["errorCode"] = errorCode.to_s
        #    @result["errorMessage"] = error
            @result = @user.errors.methods
        end
        
        @result = @result.to_json
    end
    
    def login
        
    end
end