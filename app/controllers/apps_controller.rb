class AppsController < ApplicationController
   
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
   
   def get_table
      app_id = params["app_id"]     # TODO get this from the api key
      table_name = params["table_name"]
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id || !table_name || table_name.length < 2
         errors.push(Array.new([1100, "app_id or table_name is null"]))
         status = 400
      else
         app = App.find_by_id(app_id)
         if !app
            errors.push(Array.new([1100, "The app does not exist"]))
         else
            # If the app already has this table, then create it
            table = Table.find_by(app_id: app_id, name: table_name)
            if !table
               errors.push(Array.new([1100, "The table does not exist"]))
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
      
      if ok
         @result["result"] = array
         status = 200
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
end