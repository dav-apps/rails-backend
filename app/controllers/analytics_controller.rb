class AnalyticsController < ApplicationController
   
   def create
      name = params["name"]
      app_id = params["app_id"]  # TODO change this later to api key
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !name || name.length < 2
         errors.push(Array.new([1200, "Name is null"]))
         status = 400
      else
         app = App.find_by_id(app_id)
         
         if !app
            errors.push(Array.new([1102, "The app does not exist"]))
         else
            # Find the event with the name
            event = Event.find_by(name: name, app_id: app_id)
            
            if !event
               event = Event.new(name: name, app_id: app_id)
               if !event.save
                  errors.push(Array.new([1103, "Unexpected error"]))
               end
            end
            
            log = EventLog.new(event_id: event.id)
            if log.save
               ok = true
            else
               errors.push(Array.new([1103, "Unexpected error"]))
            end
         end
      end
      
      if ok
         @result = log
         status = 201
      else
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
end