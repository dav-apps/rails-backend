class AnalyticsController < ApplicationController
   
   min_event_name_length = 2
   max_event_name_length = 15
   
   define_method :create_event_log do
      name = params["name"]
      app_id = params["app_id"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      if !name || name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
         status = 400
      end
      
      if !app_id
         errors.push(Array.new([2110, "Missing field: app_id"]))
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
               # Check if the app exists
               app = App.find_by_id(app_id)
               
               if !app
                  errors.push(Array.new([2803, "Resource does not exist: App"]))
                  status = 400
               else
                  # Check if the event with the name already exists
                  event = Event.find_by(name: name, app_id: app_id)
                  
                  if !event
                     # Validate properties
                     if name.length > max_event_name_length
                        errors.push(Array.new([2308, "Field too long: Event.name"]))
                        status = 400
                     end
                     
                     if name.length < min_event_name_length
                        errors.push(Array.new([2208, "Field too short: Event.name"]))
                        status = 400
                     end
                     
                     if errors.length == 0
                        # Create event with that name
                        event = Event.new(name: name, app_id: app_id)
                        
                        if !event.save
                           errors.push(Array.new([1103, "Unknown validation error"]))
                           status = 500
                        end
                     end
                  end
                  
                  if errors.length == 0
                     # Create event_log
                     event_log = EventLog.new(event_id: event.id)
                     
                     if !event_log.save
                        errors.push(Array.new([1103, "Unknown validation error"]))
                        status = 500
                     else
                        @result = event_log
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_event
      event_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !event_id
         errors.push(Array.new([2103, "Missing field: id"]))
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
                  # Get the app of the event
                  event = Event.find_by_id(event_id)
                  
                  if !event
                     errors.push(Array.new([2807, "Resource does not exist: Event"]))
                     status = 400
                  else
                     app = App.find_by_id(event.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this can only be called from the website
                        if !((dev == Dev.first) && (app.dev == user.dev))
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           @result["event"] = event.attributes
                           
                           logs = Array.new
                           
                           event.event_logs.each { |log| logs.push(log.attributes) }
                           
                           @result["event"]["logs"] = logs
                           ok = true
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
   
   def get_event_by_name
      event_name = params["name"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !event_name || event_name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
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
                  # Get the app of the event
                  event = Event.find_by(name: event_name)
                  
                  if !event
                     errors.push(Array.new([2807, "Resource does not exist: Event"]))
                     status = 404
                  else
                     app = App.find_by_id(event.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this can only be called from the website
                        if !((dev == Dev.first) && (app.dev == user.dev))
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           @result["event"] = event.attributes
                           
                           logs = Array.new
                           
                           event.event_logs.each { |log| logs.push(log.attributes) }
                           
                           @result["event"]["logs"] = logs
                           ok = true
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
   
   define_method :update_event do
      name = params["name"]
      event_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !event_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
      if !name || name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
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
                  event = Event.find_by_id(event_id)
                  
                  if !event
                     errors.push(Array.new([2807, "Resource does not exist: Event"]))
                     status = 400
                  else
                     app = App.find_by_id(event.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this can only be called from the website
                        if !((dev == Dev.first) && (app.dev == user.dev))
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           # Validate properties
                           if name.length > max_event_name_length
                              errors.push(Array.new([2308, "Field too long: Event.name"]))
                              status = 400
                           end
                           
                           if name.length < min_event_name_length
                              errors.push(Array.new([2208, "Field too short: Event.name"]))
                              status = 400
                           end
                           
                           if Event.exists?(name: name, app_id: app.id) && event.name != name
                              errors.push(Array.new([2703, "Field already taken: name"]))
                              status = 400
                           end
                           
                           if errors.length == 0
                              event.name = name
                              if !event.save
                                 errors.push(Array.new([1103, "Unknown validation error"]))
                                 status = 500
                              else
                                 @result = event
                                 ok = true
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
   
   def delete_event
      event_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !event_id
         errors.push(Array.new([2103, "Missing field: id"]))
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
                  # Get the app of the event
                  event = Event.find_by_id(event_id)
                  
                  if !event
                     errors.push(Array.new([2807, "Resource does not exist: Event"]))
                     status = 400
                  else
                     app = App.find_by_id(event.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this can only be called from the website
                        if !((dev == Dev.first) && (app.dev == user.dev))
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           event.destroy!
                           
                           @result = {}
                           ok = true
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
end