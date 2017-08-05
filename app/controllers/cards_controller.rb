class CardsController < ApplicationController
   require 'jwt'
   min_deck_name_length = 2
   max_deck_name_length = 20
   
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
   
   define_method :create_deck do
      name = params["name"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !name || jwt.length < 2 || name.length < 2
         errors.push(Array.new([1, "JWT or name is null"]))
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
         
         if name.length <= min_deck_name_length
            errors.push(Array.new([5, "Name is too short"]))
         end
         
         if name.length > max_deck_name_length
            errors.push(Array.new([6, "Name is too long"]))
         end
         
         if jwt_valid
            @user = User.find_by_id(decoded_jwt[0]["id"])
            
            if !@user
               errors.push(Array.new([7, "This user does not exist"]))
            else
               @deck = Deck.new(name: name, user_id: @user.id)
               
               if @deck.save && errors.length == 0
                  ok = true
               else
                  @deck.errors.each do |e|
                     if @deck.errors[e].any?
                        @deck.errors[e].each do |errorMessage|
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
         @result["deck"] = @deck
      else
         @result["saved"] = false
         @result["errors"] = errors
      end
     
      @result = @result.to_json.html_safe
   end
end