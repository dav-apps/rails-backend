class AppsController < ApplicationController
   
   # TableObject methods
   def create_object
      app_id = params["app_id"]     # TODO get this from the api key
      table_name = params["table_name"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id || !table_name || table_name.length < 2
         errors.push(Array.new([1100, "app_id or table_name is null"]))
         status = 400
      else
         # Check if content type is application/json, otherwise send status code 415
         if request.headers["Content-Type"] != "application/json"
            errors.push(Array.new([1100, "JSON expected"]))
            status = 415
         else
            app = App.find_by_id(app_id)
            if !app
               errors.push(Array.new([1100, "The app does not exist"]))
            else
               # If the app already has this table, then create it
               table = Table.find_by(app_id: app_id, name: table_name)
               if !table
                  # Create new table
                  table = Table.new(app_id: app_id, name: table_name)
                  table.save
               end
               
               # Create new object
               obj = TableObject.create(table_id: table.id, name: table_name)
               
               # Get the body of the request
               object = request.request_parameters
               
               result = Hash.new
               result["id"] = obj.id
               
               object.each do |key, value|
                  property = Property.create(table_object_id: obj.id, name: key, value: value)
                  result[key] = value
               end
               
               ok = true
            end
         end
      end
      
      if ok
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
      
      if !auth || auth.length < 2
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0   # No errors
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([0000, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(dev, api_key, sig)
               errors.push(Array.new([0000, "Authentication failed"]))
               status = 401
            else
               # Check if the object exists
               obj = TableObject.find_by_id(object_id)
               
               if !obj
                  errors.push(Array.new([0000, "Resource does not exist: Object"]))
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
      
      
      if ok
         @result = result
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end

   def update_object
      
   end
   
   def delete_object
      
   end
   
   # Table methods
   def create_table
      
   end
   # finished
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
      
      if !table_name || table_name.length < 2
         errors.push(Array.new([0000, "Missing field: table_name"]))
         status = 400
      end
      
      if !auth || auth.length < 2
         errors.push(Array.new([0000, "Missing field: auth"]))
         status = 401
      end
      
      if errors.length == 0   # No errors
         dev = Dev.find_by(api_key: api_key)
         
         if !dev     # Check if the dev exists
            errors.push(Array.new([0000, "Resource does not exist: Dev"]))
            status = 400
         else
            if !check_authorization(dev, api_key, sig)
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
      
      if ok
         @result["result"] = array
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def update_table
      
   end
   
   def delete_table
      
   end
end