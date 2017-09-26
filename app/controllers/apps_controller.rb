class AppsController < ApplicationController
   max_table_name_length = 15
   min_table_name_length = 2
   max_property_name_length = 20
   min_property_name_length = 2
   max_property_value_length = 20
   min_property_value_length = 2
   max_app_name_length = 15
   min_app_name_length = 2
   max_app_desc_length = 200
   min_app_desc_length = 3
   
   # App methods
   define_method :create_app do
      name = params["name"]
      desc = params["desc"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !name || name.length < 1
         errors.push(Array.new([0000, "Missing field: name"]))
         status = 400
      end
      
      if !desc || desc.length < 1
         errors.push(Array.new([0000, "Missing field: desc"]))
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
               if name.length < min_app_name_length
                  errors.push(Array.new([0000, "Field too short: name"]))
                  status = 400
               end
               
               if name.length > max_app_name_length
                  errors.push(Array.new([0000, "Field too long: name"]))
                  status = 400
               end
               
               if name.length < min_app_desc_length
                  errors.push(Array.new([0000, "Field too short: desc"]))
                  status = 400
               end
               
               if name.length > max_app_desc_length
                  errors.push(Array.new([0000, "Field too long: desc"]))
                  status = 400
               end
               
               if errors.length == 0
                  app = App.new(name: name, description: desc, dev_id: dev.id)
                  
                  if !app.save
                     errors.push(Array.new([0000, "Unknown validation error"]))
                     status = 500
                  else
                     result = app
                     ok = true
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   # finished
   define_method :get_app do
      app_id = params["app_id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
         status = 400
      end
      
      if !jwt || jwt.length < 1
         errors.push(Array.new([0000, "Missing field: jwt"]))
         status = 401
      end
      
      if errors.length == 0
         jwt_valid = false
         begin
             decoded_jwt = JWT.decode jwt, ENV['JWT_SECRET'], true, { :algorithm => ENV['JWT_ALGORITHM'] }
             jwt_valid = true
         rescue JWT::ExpiredSignature
             # JWT expired
             errors.push(Array.new([0000, "JWT: expired"]))
         rescue JWT::DecodeError
             errors.push(Array.new([0000, "JWT: not valid"]))
             # rescue other errors
         rescue Exception
             errors.push(Array.new([0000, "JWT: unknown error"]))
         end
         
         if jwt_valid
            user_id = decoded_jwt[0]["user_id"]
            dev_id = decoded_jwt[0]["dev_id"]
            
            user = User.find_by_id(user_id)
            
            if !user
               errors.push(Array.new([0000, "Resource does not exist: User"]))
               status = 400
            else
               dev = Dev.find_by_id(dev_id)
               
               if !dev
                  errors.push(Array.new([0000, "Resource does not exist: Dev"]))
                  status = 400
               else
                  app = App.find_by_id(app_id)
                  
                  if !app
                     errors.push(Array.new([0000, "Resource does not exist: App"]))
                     status = 404
                  else
                     if app.dev_id != dev.id
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        # Check if the dev is logged in, and not a generic user
                        if user.dev_id != dev.id
                           errors.push(Array.new([0000, "Action not allowed"]))
                           status = 403
                        else
                           result = app
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :update_app do
      app_id = params["app_id"]
      name = params["name"]
      desc = params["desc"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
         status = 400
      end
      
      if !name || name.length < 1
         errors.push(Array.new([0000, "Missing field: name"]))
         status = 400
      end
      
      if !desc || desc.length < 1
         errors.push(Array.new([0000, "Missing field: desc"]))
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
               app = App.find_by_id(app_id)
               
               if !app
                  errors.push(Array.new([0000, "Resource does not exist: App"]))
                  status = 400
               else
                  if app.dev_id != dev.id
                     errors.push(Array.new([0000, "Action not allowed"]))
                     status = 403
                  else
                     if name.length < min_app_name_length
                        errors.push(Array.new([0000, "Field too short: name"]))
                        status = 400
                     end
                     
                     if name.length > max_app_name_length
                        errors.push(Array.new([0000, "Field too long: name"]))
                        status = 400
                     end
                     
                     if name.length < min_app_desc_length
                        errors.push(Array.new([0000, "Field too short: desc"]))
                        status = 400
                     end
                     
                     if name.length > max_app_desc_length
                        errors.push(Array.new([0000, "Field too long: desc"]))
                        status = 400
                     end
                     
                     if errors.length == 0
                        # Update app
                        app.update(name: name, description: desc)
                        if !app.save
                           errors.push(Array.new([0000, "Unknown validation error"]))
                           status = 500
                        else
                           result = app
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :delete_app do
      app_id = params["app_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
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
               app = App.find_by_id(app_id)
               
               if !app
                  errors.push(Array.new([0000, "Resource does not exist: App"]))
                  status = 400
               else
                  if app.dev_id != dev.id
                     errors.push(Array.new([0000, "Action not allowed"]))
                     status = 403
                  else
                     # Delete the app
                     app.destroy!
                     result = {}
                     ok = true
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   # TableObject methods
   define_method :create_object do
      table_name = params["table_name"]
      app_id = params["app_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([0000, "Missing field: table_name"]))
         status = 400
      end
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
         status = 400
      end
      
      if !auth || auth.length < 1
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0
         if request.headers["Content-Type"] != "application/json"
            errors.push(Array.new([0000, "Content-type not supported"]))
            status = 415
         else
            dev = Dev.find_by(api_key: api_key)
            
            if !dev     # Check if the dev exists
               errors.push(Array.new([0000, "Resource does not exist: Dev"]))
               status = 400
            else
               if !check_authorization(api_key, sig)
                  errors.push(Array.new([0000, "Authentication failed"]))
                  status = 401
               else
                  app = App.find_by_id(app_id)
                  # Check if the app exists
                  if !app
                     errors.push(Array.new([0000, "Resource does not exist: App"]))
                     status = 400
                  else
                     if app.dev_id != dev.id       # Check if the app belongs to the dev
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        table = Table.find_by(name: table_name)
                        
                        if !table
                           # Check if table_name is too long or too short
                           if table_name.length > max_table_name_length
                              errors.push(Array.new([0000, "Field too long: table_name"]))
                              status = 400
                           end
                           
                           if table_name.length < min_table_name_length
                              errors.push(Array.new([0000, "Field too short: table_name"]))
                              status = 400
                           end
                           
                           if table_name.include? " "
                              errors.push(Array.new([0000, "Field contains not allowed characters: table_name"]))
                              status = 400
                           end
                           
                           # Create a new table
                           table = Table.new(app_id: app.id, name: table_name)
                           if !table.save
                              errors.push(Array.new([0000, "Unknown validation error"]))
                              status = 500
                           end
                        end
                        
                        if errors.length == 0
                           obj = TableObject.create(table_id: table.id, name: table_name)
                           
                           # Get the body of the request
                           object = request.request_parameters
                           
                           result = Hash.new
                           result["id"] = obj.id
                           
                           object.each do |key, value|
                              if !Property.create(table_object_id: obj.id, name: key, value: value)
                                 errors.push(Array.new([0000, "Unknown validation error"]))
                                 status = 500
                              else
                                 result[key] = value
                              end
                           end
                           
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_object
      object_id = params["object_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      
      if !object_id
         errors.push(Array.new([0000, "Missing field: object_id"]))
         status = 400
      end
      
      if !auth || auth.length < 1
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0   # No errors
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([0000, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(api_key, sig)
               errors.push(Array.new([0000, "Authentication failed"]))
               status = 401
            else
               # Check if the object exists
               obj = TableObject.find_by_id(object_id)
               
               if !obj
                  errors.push(Array.new([0000, "Resource does not exist: TableObject"]))
                  status = 404
               else
                  table = Table.find_by_id(obj.table_id)
                  
                  if !table
                     errors.push(Array.new([0000, "Resource does not exist: Table"]))
                     status = 400
                  else
                     app = App.find_by_id(table.app_id)
                     
                     if !app
                        errors.push(Array.new([0000, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Check if the table of the object belongs to the dev
                        if app.dev_id != dev.id
                           errors.push(Array.new([0000, "Action not allowed"]))
                           status = 403
                        else
                           # Anythink is ok
                           result = Hash.new
                           result["id"] = obj.id
                           
                           obj.properties.each do |prop|
                              result[prop.name] = prop.value
                           end
                           
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :update_object do
      object_id = params["object_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([0000, "Missing field: object_id"]))
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
               obj = TableObject.find_by_id(object_id)
               
               if !obj
                  errors.push(Array.new([0000, "Resource does not exist: TableObject"]))
                  status = 400
               else
                  table = Table.find_by_id(obj.table_id)
                  
                  if !table
                     errors.push(Array.new([0000, "Resource does not exist: Table"]))
                     status = 400
                  else
                     app = App.find_by_id(table.app_id)
                     
                     if !app
                        errors.push(Array.new([0000, "Resource does not exist: App"]))
                        status = 400
                     else
                        if app.dev_id != dev.id    # Check if the app belongs to the dev
                           errors.push(Array.new([0000, "Action not allowed"]))
                           status = 403
                        else
                           # Update the properties of the object
                           # Get the body of the request
                           object = request.request_parameters
                           
                           result = Hash.new
                           result["id"] = obj.id
                           
                           object.each do |key, value|
                              # Validate the length of the properties
                              if key.length > max_property_name_length
                                 errors.push(Array.new([0000, "Field too long: Property.name"]))
                                 status = 400
                              end
                              
                              if key.length < min_property_name_length
                                 errors.push(Array.new([0000, "Field too short: Property.name"]))
                                 status = 400
                              end
                              
                              if value.length > max_property_value_length
                                 errors.push(Array.new([0000, "Field too long: Property.value"]))
                                 status = 400
                              end
                              
                              if value.length < min_property_value_length
                                 errors.push(Array.new([0000, "Field too short: Property.value"]))
                                 status = 400
                              end
                              
                              if errors.length == 0
                                 prop = Property.find_by(name: key, table_object_id: obj.id)
                                 
                                 # If the property does not exist, create it
                                 if !prop
                                    new_prop = Property.new(name: key, value: value, table_object_id: obj.id)
                                    
                                    if !new_prop.save
                                       errors.push(Array.new([0000, "Unknown validation error"]))
                                       status = 500
                                    else
                                       result[key] = value
                                    end
                                 else
                                    prop.update(name: key, value: value)
                                    if !prop.save
                                       errors.push(Array.new([0000, "Unknown validation error"]))
                                       status = 500
                                    else
                                       result[key] = value
                                    end
                                 end
                              end
                           end
                           
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def delete_object
      object_id = params["object_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([0000, "Missing field: object"]))
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
               obj = TableObject.find_by_id(object_id)
               
               if !obj
                  errors.push(Array.new([0000, "Resource does not exist: TableObject"]))
                  status = 400
               else
                  table = Table.find_by_id(obj.table_id)
                  
                  if !table
                     errors.push(Array.new([0000, "Resource does not exist: Table"]))
                     status = 400
                  else
                     app = App.find_by_id(table.app_id)
                     
                     if !app
                        errors.push(Array.new([0000, "Resource does not exist: App"]))
                        status = 400
                     else
                        if app.dev_id != dev.id
                           errors.push(Array.new([0000, "Action not allowed"]))
                           status = 403
                        else
                           obj.destroy!
                           result = {}
                           ok = true
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   # Table methods
   define_method :create_table do
      table_name = params["table_name"]
      app_id = params["app_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([0000, "Missing field: table_name"]))
         status = 400
      end
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
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
               app = App.find_by_id(app_id)
               # Check if the app exists
               if !app
                  errors.push(Array.new([0000, "Resource does not exist: App"]))
                  status = 400
               else
                  table = Table.find_by(name: table_name)
                  
                  if table
                     errors.push(Array.new([0000, "Resource already exists"]))
                     status = 202
                  else
                     if app.dev_id != dev.id
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        # Check if table_name is too long or too short
                        if table_name.length > max_table_name_length
                           errors.push(Array.new([0000, "Field too long: table_name"]))
                           status = 400
                        end
                        
                        if table_name.length < min_table_name_length
                           errors.push(Array.new([0000, "Field too short: table_name"]))
                           status = 400
                        end
                        
                        if table_name.include? " "
                           errors.push(Array.new([0000, "Field contains not allowed characters: table_name"]))
                           status = 400
                        end
                        
                        if errors.length == 0
                           # Create the new table and return it
                           table = Table.new(name: table_name.capitalize, app_id: app.id)
                           if !table.save
                              errors.push(Array.new([0000, "Unknown validation error"]))
                              status = 500
                           else
                              result = table
                              ok = true
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_table
      app_id = params["app_id"]
      table_name = params["table_name"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
         errors.push(Array.new([0000, "Missing field: app_id"]))
         status = 400
      end
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([0000, "Missing field: table_name"]))
         status = 400
      end
      
      if !auth || auth.length < 1
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0   # No errors
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([0000, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(api_key, sig)
               errors.push(Array.new([0000, "Authentication failed"]))
               status = 401
            else
               app = App.find_by_id(app_id)
               if !app     # Check if the app exist
                  errors.push(Array.new([0000, "Resource not found: App"]))
                  status = 400
               else
                  table = Table.find_by(app_id: app_id, name: table_name)
                  if !table
                     errors.push(Array.new([0000, "Resource does not exist: Table"]))
                     status = 404
                  else
                     # Check if the table belongs to the dev
                     if app.dev_id != dev.id
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        array = Array.new
                        
                        table.table_objects.each do |table_object|
                           object = Hash.new
                           object["id"] = table_object.id
                           
                           table_object.properties.each do |property|
                              object[property.name] = property.value
                           end
                           array.push(object)
                        end
                        
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result["result"] = array
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :update_table do
      table_id = params["table_id"]
      table_name = params["table_name"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_id
         errors.push(Array.new([0000, "Missing field: table_id"]))
         status = 400
      end
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([0000, "Missing field: table_name"]))
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
               table = Table.find_by_id(table_id)
               
               if !table
                  errors.push(Array.new([0000, "Resource does not exist: Table"]))
                  status = 400
               else
                  app = App.find_by_id(table.app_id)
                  
                  if !app
                     errors.push(Array.new([0000, "Resource does not exist: App"]))
                     status = 400
                  else
                     # Check if the app belongs to the dev
                     if app.dev_id != dev.id
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        # Validate the table name
                        if table_name.length > max_table_name_length
                           errors.push(Array.new([0000, "Field too long: table_name"]))
                           status = 400
                        end
                        
                        if table_name.length < min_table_name_length
                           errors.push(Array.new([0000, "Field too short: table_name"]))
                           status = 400
                        end
                        
                        if table_name.include? " "
                           errors.push(Array.new([0000, "Field contains not allowed characters: table_name"]))
                           status = 400
                        end
                        
                        if errors.length == 0
                           # Update the table and send it back
                           if !table.update(name: table_name.capitalize)
                              errors.push(Array.new([0000, "Unknown validation error"]))
                              status = 500
                           else
                              result = table
                              ok = true
                           end
                        end
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def delete_table
      table_id = params["table_id"]
      
      auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s : request.headers['HTTP_AUTHORIZATION'].to_s
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_id
         errors.push(Array.new([0000, "Missing field: table_name"]))
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
               table = Table.find_by_id(table_id)
               
               if !table
                  errors.push(Array.new([0000, "Resource does not exist: Table"]))
                  status = 400
               else
                  app = App.find_by_id(table.app_id)
                  
                  if !app
                     errors.push(Array.new([0000, "Resource does not exist: App"]))
                     status = 400
                  else
                     if app.dev_id != dev.id
                        errors.push(Array.new([0000, "Action not allowed"]))
                        status = 403
                     else
                        # Delete the table
                        table.destroy!
                        result = {}
                        ok = true
                     end
                  end
               end
            end
         end
      end
      
      if ok && errors.length == 0
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
end