class AnalyticsController < ApplicationController
   
   min_event_name_length = 2
	max_event_name_length = 15
	max_event_data_length = 65000
	min_property_name_length = 1
	max_property_name_length = 100
	min_property_value_length = 1
   max_property_value_length = 65000
   
	define_method :create_event_log do
		api_key = params["api_key"]
		name = params["name"]
		app_id = params["app_id"]
		save_country = params["save_country"]

		errors = Array.new
      @result = Hash.new
		ok = false

		if !api_key || api_key.length < 1
			errors.push(Array.new([2118, "Missing field: name"]))
         status = 400
		end
		
		if !name || name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
         status = 400
		end
		
		if !app_id
         errors.push(Array.new([2110, "Missing field: app_id"]))
         status = 400
		end
		
		if errors.length == 0
			dev = Dev.find_by(api_key: api_key)

			if !dev
				errors.push(Array.new([2802, "Resource does not exist: Dev"]))
            status = 400
			else
				app = App.find_by_id(app_id)

				if !app
					errors.push(Array.new([2803, "Resource does not exist: App"]))
					status = 400
				else
					# Check if the app belongs to the dev
					if app.dev != dev
						errors.push(Array.new([1102, "Action not allowed"]))
						status = 403
					else
						if request.headers["Content-Type"] == nil
							content_type = ""
						else
							content_type = request.headers["Content-Type"]
						end

						if !content_type.include?("application/json") && request.body.string.length > 0
							errors.push(Array.new([1104, "Content-type not supported"]))
							status = 415
						else
							# Check if the event with the name already exists
							event = Event.find_by(name: name, app_id: app_id)

							if !event
								# Validate properties
								if name.length > max_event_name_length
									errors.push(Array.new([2303, "Field too long: name"]))
									status = 400
								end
								
								if name.length < min_event_name_length
									errors.push(Array.new([2203, "Field too short: name"]))
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

							object = request.request_parameters

							object.each do |key, value|
								# Validate the length of the properties
								if key.length > max_property_name_length
									errors.push(Array.new([2306, "Field too long: Property.name"]))
									status = 400
								end
								
								if key.length < min_property_name_length
									errors.push(Array.new([2206, "Field too short: Property.name"]))
									status = 400
								end
								
								if value.length > max_property_value_length
									errors.push(Array.new([2307, "Field too long: Property.value"]))
									status = 400
								end
								
								if value.length < min_property_value_length
									errors.push(Array.new([2207, "Field too short: Property.value"]))
									status = 400
								end
							end

							if errors.length == 0
								# Create the event_log
								event_log = EventLog.new(event_id: event.id)

								if !event_log.save
									errors.push(Array.new([1103, "Unknown validation error"]))
									status = 500
								else
									properties = Hash.new
								
									object.each do |key, value|
										if !EventLogProperty.create(event_log_id: event_log.id, name: key, value: value)
											errors.push(Array.new([1103, "Unknown validation error"]))
											status = 500
										else
											properties[key] = value
										end
									end
								end

								if errors.length == 0
									if save_country
										# Get the country code and save it as event_log_property
										ip = request.remote_ip
	
										begin
											country_key = "country"

											country_code = JSON.parse(IpinfoIo::lookup(ip).body)["country"]
											puts country_code
	
											ip_property = EventLogProperty.new(event_log_id: event_log.id, name: country_key, value: country_code)
											if ip_property.save
												properties[country_key] = country_code
											end
										rescue StandardError => e
											puts e
										end
									end
	
									@result = event_log.attributes
									@result["properties"] = properties
									ok = true
								end
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
						# Get the event
						event = Event.find_by(id: event_id)

						if !event
							errors.push(Array.new([2807, "Resource does not exist: Event"]))
							status = 400
						else
							# Get the app
							app = App.find_by_id(event.app_id)

							if !app
								errors.push(Array.new([2803, "Resource does not exist: App"]))
								status = 400
							else
								# Check if the app belongs to the dev
								if app.dev != dev
									errors.push(Array.new([1102, "Action not allowed"]))
									status = 403
								else
									# Make sure this can only be called from the website
									if !((dev == Dev.first) && (app.dev == user.dev))
										errors.push(Array.new([1102, "Action not allowed"]))
										status = 403
									else
										@result = event.attributes
										
										logs = Array.new
										event.event_logs.each do |log|
											log_hash = Hash.new
											properties = Hash.new

											log.event_log_properties.each do |property|
												properties[property.name] = property.value
											end

											log_hash["id"] = log.id
											log_hash["created_at"] = log.created_at
											log_hash["properties"] = properties
											logs.push(log_hash)
										end

										@result["logs"] = logs
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
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_event_by_name
		event_name = params["name"]
		app_id = params["app_id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !event_name || event_name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
         status = 400
		end
		
		if !app_id
         errors.push(Array.new([2110, "Missing field: app_id"]))
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
						app = App.find_by_id(app_id)
                  
						if !app
							errors.push(Array.new([2803, "Resource does not exist: App"]))
							status = 400
						else
							# Get the app of the event
							event = Event.find_by(name: event_name, app: app_id)
							
							if !event
								errors.push(Array.new([2807, "Resource does not exist: Event"]))
								status = 404
							else
								# Make sure this can only be called from the website
								if !((dev == Dev.first) && (app.dev == user.dev))
									errors.push(Array.new([1102, "Action not allowed"]))
									status = 403
								else
									@result = event.attributes
									
									logs = Array.new
									event.event_logs.each do |log|
										log_hash = Hash.new
										properties = Hash.new

										log.event_log_properties.each do |property|
											properties[property.name] = property.value
										end

										log_hash["id"] = log.id
										log_hash["created_at"] = log.created_at
										log_hash["properties"] = properties
										logs.push(log_hash)
									end

									@result["logs"] = logs

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
                           if request.headers["Content-Type"] != "application/json" && request.headers["Content-Type"] != "application/json; charset=utf-8"
                              errors.push(Array.new([1104, "Content-type not supported"]))
                              status = 415
                           else
                              object = request.request_parameters
                              
                              name = object["name"]
                              if name
                                 # Validate properties
                                 if name.length > max_event_name_length
                                    errors.push(Array.new([2303, "Field too long: name"]))
                                    status = 400
                                 end
                                 
                                 if name.length < min_event_name_length
                                    errors.push(Array.new([2203, "Field too short: name"]))
                                    status = 400
                                 end
                                 
                                 if Event.exists?(name: name, app_id: app.id) && event.name != name
                                    errors.push(Array.new([2703, "Field already taken: name"]))
                                    status = 400
                                 end
                                 
                                 if errors.length == 0
                                    event.name = name
                                 end
                              end
                           end
                           
                           if errors.length == 0
                              if !event.save
                                 errors.push(Array.new([1103, "Unknown validation error"]))
                                 status = 500
                              else
                                 @result = event.attributes
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
	
	def get_app
		id = params[:id]
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		errors = Array.new
      @result = Hash.new
		ok = false
		
		if !id
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
						app = App.find_by_id(id)

						if !app
							errors.push(Array.new([2803, "Resource does not exist: App"]))
							status = 404
						else
							# Check if the app belongs to the dev
							if dev != Dev.first
								errors.push(Array.new([1102, "Action not allowed"]))
								status = 403
							else
								if user.dev != app.dev
									errors.push(Array.new([1102, "Action not allowed"]))
									status = 403
								else
									# Return the requested information
									users = Array.new
									
									app.users_apps.each do |users_app|
										hash = Hash.new
										hash["id"] = users_app.user_id
										hash["started_using"] = users_app.created_at

										users.push(hash)
									end

									@result["users"] = users
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

	def get_users
		jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last

		errors = Array.new
      @result = Hash.new
		ok = false

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
						if dev != Dev.first
							errors.push(Array.new([1102, "Action not allowed"]))
							status = 403
						else
							if user.dev != dev
								errors.push(Array.new([1102, "Action not allowed"]))
								status = 403
							else
								# Return the requested information
								users = Array.new

								User.all.each do |user|
									hash = Hash.new

									hash["id"] = user.id
									hash["created_at"] = user.created_at
									hash["updated_at"] = user.updated_at
									hash["confirmed"] = user.confirmed
									hash["plan"] = user.plan

									apps = Array.new
									user.apps.each do |app|
										app_hash = Hash.new
										app_hash["id"] = app.id
										app_hash["name"] = app.name
										apps.push(app_hash)
									end

									hash["apps"] = apps

									users.push(hash)
								end

								@result["users"] = users
								ok = true
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