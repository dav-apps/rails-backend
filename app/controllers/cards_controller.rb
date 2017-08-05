class CardsController < ApplicationController
   require 'jwt'
   
   def get_all_decks_and_cards
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || jwt.length < 2
         errors.push(Array.new([1, "JWT is null"]))
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
         
         if jwt_valid
            @user = User.find_by_id(decoded_jwt[0]["id"])
            
            if !@user
               errors.push(Array.new([5, "This user does not exist"]))
            else
               ok = true
            end
         end
      end
      
      if ok
         @result["access"] = true
         
         @result["decks"] = @user.decks
         @result["cards"] = @user.cards
         
         @user.uses_cards = true
         @user.save!
      else
         @result["access"] = false
         @result["errors"] = errors
      end
      
      @result = @result.to_json.html_safe
   end
end