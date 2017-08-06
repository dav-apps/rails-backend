class CardsController < ApplicationController
   require 'jwt'
   min_deck_name_length = 2
   max_deck_name_length = 20
   min_card_page_length = 2
   max_card_page_length = 25
   
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
         
         if name.length < min_deck_name_length
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
   
   define_method :update_deck do
      deck_id = params["deck_id"]
      name = params["name"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !name || jwt.length < 2 || name.length < 2
         errors.push(Array.new([1, "JWT, deck_id or name is null"]))
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
         
         if name.length < min_deck_name_length
            errors.push(Array.new([5, "Name is too short"]))
         end
         
         if name.length > max_deck_name_length
            errors.push(Array.new([6, "Name is too long"]))
         end
         
         if jwt_valid
            @user = User.find_by_id(decoded_jwt[0]["id"])
            @deck = Deck.find_by_id(deck_id)
            
            if !@user
               errors.push(Array.new([7, "This user does not exist"]))
            else
               if !@deck
                  errors.push(Array.new([8, "This deck does not exist"]))
               else
                  if @deck.user_id != @user.id
                     errors.push(Array.new([9, "You don't own this deck"]))
                  else
                     @deck.name = name
                     
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
   
   def delete_deck
      deck_id = params["deck_id"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !deck_id || jwt.length < 2
         errors.push(Array.new([1, "JWT, deck_id or name is null"]))
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
            @deck = Deck.find_by_id(deck_id)
            
            if !@user
               errors.push(Array.new([5, "This user does not exist"]))
            else
               if !@deck
                  errors.push(Array.new([6, "This deck does not exist"]))
               else
                  if @deck.user_id != @user.id
                     errors.push(Array.new([7, "You don't own this deck"]))
                  else
                     if @deck.destroy && errors.length == 0
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
         end
      end
      
      if ok
         @result["deleted"] = true
      else
         @result["deleted"] = false
         @result["errors"] = errors
      end
      
      @result = @result.to_json.html_safe
   end
   
   define_method :create_card do
      page1 = params["page1"]
      page2 = params["page2"]
      deck_id = params["deck_id"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !page1 || !page2 || !deck_id || jwt.length < 2 || page1.length < 1 || page2.length < 1
         errors.push(Array.new([1, "JWT, page1, page2 or deck id is null"]))
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
         
         if page1.length < min_card_page_length
            errors.push(Array.new([5, "Page1 is too short"]))
         end
         
         if page2.length < min_card_page_length
            errors.push(Array.new([6, "Page2 is too short"]))
         end
         
         if page1.length > max_card_page_length
            errors.push(Array.new([7, "Page1 is too long"]))
         end
         
         if page2.length > max_card_page_length
            errors.push(Array.new([8, "Page2 is too long"]))
         end
         
         if jwt_valid
            @user = User.find_by_id(decoded_jwt[0]["id"])
            
            if !@user
               errors.push(Array.new([9, "This user does not exist"]))
            else
               @deck = Deck.find_by_id(deck_id)
               
               if !@deck
                  errors.push(Array.new([10, "This Deck does not exist"]))
               else
                  if @deck.user_id != @user.id
                     errors.push(Array.new([11, "You don't own this deck"]))
                  end
               end
               
               @card = Card.new(page1: page1, page2: page2, deck_id: deck_id)
               
               if @card.save && errors.length == 0
                  ok = true
               else
                  @card.errors.each do |e|
                     if @card.errors[e].any?
                        @card.errors[e].each do |errorMessage|
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
         @result["card"] = @card
         @result["deck"] = @deck
      else
         @result["saved"] = false
         @result["errors"] = errors
      end
     
      @result = @result.to_json.html_safe
   end
   
   define_method :update_card do
      card_id = params["card_id"]
      deck_id = params["deck_id"]
      page1 = params["page1"]
      page2 = params["page2"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !card_id || !deck_id || !page1 || !page2 || jwt.length < 2 || page1.length < 1 || page2.length < 1
         errors.push(Array.new([1, "JWT, deck_id, card_id, page1 or page2 is null"]))
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
         
         if page1.length < min_card_page_length
            errors.push(Array.new([5, "Page1 is too short"]))
         end
         
         if page2.length < min_card_page_length
            errors.push(Array.new([6, "Page2 is too short"]))
         end
         
         if page1.length > max_card_page_length
            errors.push(Array.new([7, "Page1 is too long"]))
         end
         
         if page2.length > max_card_page_length
            errors.push(Array.new([8, "Page2 is too long"]))
         end
         
         if jwt_valid
            @user = User.find_by_id(decoded_jwt[0]["id"])
            
            if !@user
               errors.push(Array.new([9, "This user does not exist"]))
            else
               @card = Card.find_by_id(card_id)
               
               if !@card
                  errors.push(Array.new([10, "This Card does not exist"]))
               else
                  @deck = Deck.find_by_id(deck_id)
               
                  if !@deck
                     errors.push(Array.new([11, "This Deck does not exist"]))
                  else
                     if @deck.user_id != @user.id
                        errors.push(Array.new([12, "You don't own this deck"]))
                     else
                        @card.deck_id = deck_id
                        @card.page1 = page1
                        @card.page2 = page2
                        
                        if @card.save && errors.length == 0
                           ok = true
                        else
                           @card.errors.each do |e|
                              if @card.errors[e].any?
                                 @card.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok
         @result["saved"] = true
         @result["card"] = @card
      else
         @result["saved"] = false
         @result["errors"] = errors
      end
      
      @result = @result.to_json.html_safe
   end
   
   def delete_card
      card_id = params["card_id"]
      jwt = request.headers['HTTP_AUTHORIZATION']
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !jwt || !card_id || jwt.length < 2
         errors.push(Array.new([1, "JWT or card_id is null"]))
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
            @card = Card.find_by_id(card_id)
            
            if !@user
               errors.push(Array.new([5, "This user does not exist"]))
            else
               if !@card
                  errors.push(Array.new([6, "This card does not exist"]))
               else
                  @deck = Deck.find_by_id(@card.deck_id)
                  
                  if !@deck
                     errors.push(Array.new([7, "The deck of this card does not exist"]))
                  else
                     if @deck.user_id != @user.id
                        errors.push(Array.new([8, "You don't own the deck of this card"]))
                     else
                        if @card.destroy && errors.length == 0
                           ok = true
                        else
                           @card.errors.each do |e|
                              if @card.errors[e].any?
                                 @card.errors[e].each do |errorMessage|
                                    errors.push(Array.new([0, e.to_s + " " + errorMessage.to_s]))
                                 end
                              end
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok
         @result["deleted"] = true
      else
         @result["deleted"] = false
         @result["errors"] = errors
      end
      
      @result = @result.to_json.html_safe
   end
end