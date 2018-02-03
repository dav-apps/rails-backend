class AppsController < ApplicationController
   max_table_name_length = 15
   min_table_name_length = 2
   max_property_name_length = 20
   min_property_name_length = 1
   max_property_value_length = 1000
   min_property_value_length = 1
   max_app_name_length = 30
   min_app_name_length = 2
   max_app_desc_length = 500
	min_app_desc_length = 3
	link_blank_string = "_"
   
   # App methods
   define_method :create_app do
      name = params["name"]
      desc = params["desc"]
      link_web = params["link_web"]
      link_play = params["link_play"]
      link_windows = params["link_windows"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !name || name.length < 1
         errors.push(Array.new([2111, "Missing field: name"]))
         status = 400
      end
      
      if !desc || desc.length < 1
         errors.push(Array.new([2112, "Missing field: desc"]))
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
               
               if !dev || !user.dev
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Make sure this is only called from the website
                  if dev != Dev.first
                     errors.push(Array.new([1102, "Action not allowed"]))
                     status = 403
                  else
                     if name.length < min_app_name_length
                        errors.push(Array.new([2203, "Field too short: name"]))
                        status = 400
                     end
                     
                     if name.length > max_app_name_length
                        errors.push(Array.new([2303, "Field too long: name"]))
                        status = 400
                     end
                     
                     if desc.length < min_app_desc_length
                        errors.push(Array.new([2204, "Field too short: desc"]))
                        status = 400
                     end
                     
                     if desc.length > max_app_desc_length
                        errors.push(Array.new([2304, "Field too long: desc"]))
                        status = 400
							end
							
							if link_web
								if link_web == link_blank_string
									link_web = ""
								elsif !validate_url(link_web)
									# Invalid link
									errors.push(Array.new([2402, "Field not valid: link_web"]))
									status = 400
								end
							end

							if link_play
								if link_play == link_blank_string
									link_play = ""
								elsif !validate_url(link_play)
									# Invalid link
									errors.push(Array.new([2403, "Field not valid: link_play"]))
									status = 400
								end
							end

							if link_windows
								if link_windows == link_blank_string
									link_windows = ""
								elsif !validate_url(link_windows)
									# Invalid link
									errors.push(Array.new([2404, "Field not valid: link_windows"]))
									status = 400
								end
							end
							
                     
                     if errors.length == 0
                        app = App.new(name: name, description: desc, dev_id: user.dev.id)

                        # Save existing links
                        if link_web
                           app.link_web = link_web
                        end

                        if link_play
                           app.link_play = link_play
                        end

                        if link_windows
                           app.link_windows = link_windows
                        end
                        

                        if !app.save
                           errors.push(Array.new([1103, "Unknown validation error"]))
                           status = 500
                        else
                           @result = app
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
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   define_method :get_app do
      app_id = params["id"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
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
                  app = App.find_by_id(app_id)
                  
                  if !app
                     errors.push(Array.new([2803, "Resource does not exist: App"]))
                     status = 404
                  else
                     # Make sure this is called from the website or from the associated dev
                     if !(((dev == Dev.first) && (app.dev == user.dev)) || user.dev == dev)
                        errors.push(Array.new([1102, "Action not allowed"]))
                        status = 403
                     else
                        tables = Array.new
                        
                        app.tables.each do |table|
                           tables.push(table)
                        end
                     
                        @result = app.attributes
                        @result["tables"] = tables
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

	define_method :get_all_apps do
		auth = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["auth"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      if auth
         api_key = auth.split(",")[0]
         sig = auth.split(",")[1]
      end

		errors = Array.new
      @result = Hash.new
		ok = false

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
					if dev != Dev.first
						errors.push(Array.new([1102, "Action not allowed"]))
						status = 403
					else
						# Get all apps and return them
						apps = App.all
						apps_array = Array.new

						apps.each do |app|
							if app.published
								apps_array.push(app.attributes)
							end
						end
						@result["apps"] = apps_array
						ok = true
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
   
   define_method :update_app do
      app_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
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
                  app = App.find_by_id(app_id)
               
                  if !app
                     errors.push(Array.new([2803, "Resource does not exist: App"]))
                     status = 400
                  else
                     # Make sure this is only called from the website and from the dev of the app
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
                              if name.length < min_app_name_length
                                 errors.push(Array.new([2203, "Field too short: name"]))
                                 status = 400
                              end
                              
                              if name.length > max_app_name_length
                                 errors.push(Array.new([2303, "Field too long: name"]))
                                 status = 400
                              end
                              
                              if errors.length == 0
                                 app.name = name
                              end
                           end
                           
                           desc = object["description"]
                           if desc
                              if desc.length < min_app_desc_length
                                 errors.push(Array.new([2204, "Field too short: description"]))
                                 status = 400
                              end
                              
                              if desc.length > max_app_desc_length
                                 errors.push(Array.new([2304, "Field too long: description"]))
                                 status = 400
                              end
                              
                              if errors.length == 0
                                 app.description = desc
                              end
									end
									
									link_web = object["link_web"]
									if link_web
										if link_web == link_blank_string
											app.link_web = ""
										elsif !validate_url(link_web)
											# Invalid link
											errors.push(Array.new([2402, "Field not valid: link_web"]))
											status = 400
										else
											app.link_web = link_web
										end
									end

									link_play = object["link_play"]
									if link_play
										if link_play == link_blank_string
											app.link_play = ""
										elsif !validate_url(link_play)
											# Invalid link
											errors.push(Array.new([2403, "Field not valid: link_play"]))
											status = 400
										else
											app.link_play = link_play
										end
									end

									link_windows = object["link_windows"]
									if link_windows
										if link_windows == link_blank_string
											app.link_windows = ""
										elsif !validate_url(link_windows)
											# Invalid link
											errors.push(Array.new([2404, "Field not valid: link_windows"]))
											status = 400
										else
											app.link_windows = link_windows
										end
									end
                        end
                        
                        if errors.length == 0
                           # Update app
                           if !app.save
                              errors.push(Array.new([1103, "Unknown validation error"]))
                              status = 500
                           else
                              @result = app
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
   
   define_method :delete_app do
      app_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
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
                  app = App.find_by_id(app_id)
                  
                  if !app
                     errors.push(Array.new([2803, "Resource does not exist: App"]))
                     status = 400
                  else
                     if !((dev == Dev.first) && (app.dev == user.dev)) # Make sure this is only called from the website
                        errors.push(Array.new([1102, "Action not allowed"]))
                        status = 403
                     else
                        app.destroy!
                        @result = {}
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
   
   # TableObject methods
   define_method :create_object do
      table_name = params["table_name"]
      app_id = params["app_id"]
		visibility = params["visibility"]
		ext = params["ext"]
		uuid = params["uuid"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
		ok = false
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([2113, "Missing field: table_name"]))
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
						# Check if the app exists
						if !app
							errors.push(Array.new([2803, "Resource does not exist: App"]))
							status = 400
						else
							if app.dev_id != dev.id       # Check if the app belongs to the dev
								errors.push(Array.new([1102, "Action not allowed"]))
								status = 403
							else
								table = Table.find_by(name: table_name, app_id: app_id)
								
								if !table
									# Only create the table when the dev is logged in
									if dev.user_id != user.id
										errors.push(Array.new([2804, "Resource does not exist: Table"]))
										status = 400
									else
										# Check if table_name is too long or too short
										if table_name.length > max_table_name_length
											errors.push(Array.new([2305, "Field too long: table_name"]))
											status = 400
										end
										
										if table_name.length < min_table_name_length
											errors.push(Array.new([2205, "Field too short: table_name"]))
											status = 400
										end
										
										if table_name.include? " "
											errors.push(Array.new([2501, "Field contains not allowed characters: table_name"]))
											status = 400
										end
										
										# Create a new table
										table = Table.new(app_id: app.id, name: (table_name[0].upcase + table_name[1..-1]))
										if !table.save
											errors.push(Array.new([1103, "Unknown validation error"]))
											status = 500
										end
									end
								end

								# Check if the uuid is already in use
								if uuid
									object = TableObject.find_by(uuid: uuid)

									if object
										errors.push(Array.new([2704, "Field already taken: uuid"]))
										status = 400
									end
								end

								if request.headers["Content-Type"] == "application/x-www-form-urlencoded"
									errors.push(Array.new([1104, "Content-type not supported"]))
									status = 415
								end


								obj = TableObject.new(table_id: table.id, user_id: user.id)

								if uuid
									obj.uuid = uuid
								else
									obj.uuid = SecureRandom.uuid
								end
								
								begin
									if visibility && visibility.to_i <= 2 && visibility.to_i >= 0
										obj.visibility = visibility.to_i
									end
								end


								# If ext there is an ext property, save object as a file
								if !ext || ext.length < 1
									# If there is no ext, Content-Type must be application/json
									if !request.headers["Content-Type"].include? "application/json"
										errors.push(Array.new([1104, "Content-type not supported"]))
										status = 415
									else		# Save object normally
										if errors.length == 0
											if !obj.save
												errors.push(Array.new([1103, "Unknown validation error"]))
												status = 500
											else
												# Get the body of the request
												object = request.request_parameters
												
												if object.length < 1
													errors.push(Array.new([2116, "Missing field: object"]))
													status = 400
												else
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
												end
												
												if errors.length == 0
													properties = Hash.new
													
													object.each do |key, value|
														if !Property.create(table_object_id: obj.id, name: key, value: value)
															errors.push(Array.new([1103, "Unknown validation error"]))
															status = 500
														else
															properties[key] = value
														end
													end
													
													# Save that user uses the app
													if !user.apps.find_by_id(app.id)
														users_app = UsersApp.create(app_id: app.id, user_id: user.id)
														users_app.save
													end
													
													@result = obj.attributes
													@result["properties"] = properties
													
													ok = true
												end
											end
										end
									end
								else
									# Check if the user has enough free storage
									file_size = get_file_size(request.body)
									free_storage = get_total_storage_of_user(user.id) - get_used_storage_of_user(user.id)
									obj.file = true

									if free_storage < file_size
										errors.push(Array.new([1110, "Not enough storage space"]))
										status = 400
									end

									if errors.length == 0
										if !obj.save
											errors.push(Array.new([1103, "Unknown validation error"]))
											status = 500
										else
											begin
												upload_blob(app.id, obj.id, request.body)

												# Save extension as property
												ext_prop = Property.new(table_object_id: obj.id, name: "ext", value: ext)

												if !ext_prop.save
													errors.push(Array.new([1103, "Unknown validation error"]))
													status = 500
												else
													size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)

													if !size_prop.save
														errors.push(Array.new([1103, "Unknown validation error"]))
														status = 500
													else
														# Save that user uses the app
														if !user.apps.find_by_id(app.id)
															users_app = UsersApp.create(app_id: app.id, user_id: user.id)
															users_app.save
														end

														@result = obj.attributes

														properties = Hash.new
														obj.properties.each do |prop|
															properties[prop.name] = prop.value
														end
	
														@result["properties"] = properties
														ok = true
													end
												end
											rescue Exception => e
												errors.push(Array.new([1103, "Unknown validation error"]))
												status = 500
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
      
      if ok && errors.length == 0
         status = 201
      else
         @result.clear
         @result["errors"] = errors
      end
		
		render json: @result, status: status if status
   end
   
   def get_object
      object_id = params["id"]
		token = params["access_token"]
		file = params["file"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      can_access = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
      end
      
		if errors.length == 0 
			obj = TableObject.find_by_id(object_id)

			if !obj
				obj = TableObject.find_by(uuid: object_id)
			end
         
         if !obj
            errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
            status = 404
         else
            table = Table.find_by_id(obj.table_id)
            
            if !table
               errors.push(Array.new([2804, "Resource does not exist: Table"]))
               status = 400
            else
               app = App.find_by_id(table.app_id)
               
               if !app
                  errors.push(Array.new([2803, "Resource does not exist: App"]))
                  status = 400
               else
                  # Check the visibility
                  if obj.visibility != 2
                     # Check JWT
                     if !jwt || jwt.length < 1
                        # Check access_token
                        if !token || token.length < 1
                           # Token and JWT missing
                           if !token || token.length < 1
                              errors.push(Array.new([2117, "Missing field: access_token"]))
                              status = 400
                           end
                           
                           if !jwt || jwt.length < 1
                              errors.push(Array.new([2102, "Missing field: jwt"]))
                              status = 401
                           end
                        else
                           # Check if the token is valid
                           obj.access_tokens.each do |access_token|
                              if access_token.token == token
                                 can_access = true
                              end
                           end
                        end
                     else
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
                              
                              if !dev     # Check if the dev exists
                                 errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                                 status = 400
                              else
                                 # Check if the app belongs to the dev
                                 if app.dev_id != dev.id
                                    errors.push(Array.new([1102, "Action not allowed"]))
                                    status = 403
                                 else
                                    if obj.user_id != user.id   # Check if the object belongs to the user
                                       if obj.visibility == 0
                                          errors.push(Array.new([1102, "Action not allowed"]))
                                          status = 403
                                       else
                                          can_access = true
                                       end
                                    else  # Object does belong to the user
                                       can_access = true
                                    end
                                 end
                              end
                           end
                        end
                     end
						else
							# Visibility == 2
                     can_access = true
                  end
               end
            end
         end
         
			if errors.length == 0 && can_access
				if file == "true" && obj.file
					# Return the file
					Azure.config.storage_account_name = ENV["AZURE_STORAGE_ACCOUNT"]
					Azure.config.storage_access_key = ENV["AZURE_STORAGE_ACCESS_KEY"]
					filename = "#{app.id}/#{obj.id}"

					begin
						client = Azure::Blob::BlobService.new
						blob = client.get_blob(ENV["AZURE_FILES_CONTAINER_NAME"], filename)

						@result = blob[1]

						# Get the file extension
						obj.properties.each do |prop|
							if prop.name == "ext"
								filename += ".#{prop.value}"
							end
						end
						
						ok = true
						file = true
					rescue Exception => e
						errors.push(Array.new([1111, "File does not exist"]))
            		status = 400
					end
				else
					@result = obj.attributes
					properties = Hash.new
					obj.properties.each do |prop|
						properties[prop.name] = prop.value
					end
					@result["properties"] = properties

					ok = true
					file = false
				end
         elsif errors.length == 0 && !can_access
            errors.push(Array.new([1102, "Action not allowed"]))
            status = 403
         end
      end
      
      if ok && errors.length == 0
         status = 200
      else
			@result.clear
         @result["errors"] = errors
      end
		
		if file
			if status
				send_data(@result, status: status, filename: filename)
			else
				send_data(@result)
			end
		else
			render json: @result, status: status if status
		end
   end
   
   define_method :update_object do
      object_id = params["id"]
		visibility = params["visibility"]
		ext = params["ext"]
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						obj = TableObject.find_by_id(object_id)

						if !obj
							obj = TableObject.find_by(uuid: object_id)
						end
						
                  if !obj
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
                  else
                     table = Table.find_by_id(obj.table_id)
							
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
                     else
                        app = App.find_by_id(table.app_id)
								
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
                        else
                           if app.dev_id != dev.id    # Check if the app belongs to the dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
                           else
                              # Check if the user is allowed to access the data
                              if obj.user_id != user.id
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											if (request.headers["Content-Type"] == "application/json" ||
												request.headers["Content-Type"] == "application/json; charset=utf-8") &&
												request.content_type == "application/json"

												# Update the properties of the object
												# Get the body of the request
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
													properties = Hash.new
													object.each do |key, value|
														prop = Property.find_by(name: key, table_object_id: obj.id)
														
														# If the property does not exist, create it
														if !prop
															new_prop = Property.new(name: key, value: value, table_object_id: obj.id)
															
															if !new_prop.save
																errors.push(Array.new([1103, "Unknown validation error"]))
																status = 500
															else
																properties[key] = value
															end
														else
															prop.update(name: key, value: value)
															if !prop.save
																errors.push(Array.new([1103, "Unknown validation error"]))
																status = 500
															else
																properties[key] = value
															end
														end
													end
													
													# If there is a new visibility, save it
													begin
														if visibility && visibility.to_i <= 2 && visibility.to_i >= 0
															obj.visibility = visibility.to_i
															
															if !obj.save
																errors.push(Array.new([1103, "Unknown validation error"]))
																status = 500
															end
														end
													end
													
													@result = obj.attributes
													@result["properties"] = properties
													
													ok = true
												end
											else
												if errors.length == 0
													# If there is a new visibility, save it
													begin
														if visibility && visibility.to_i <= 2 && visibility.to_i >= 0
															obj.visibility = visibility.to_i
														end
													end

													if ext && ext.length > 0
														# Update ext property
														ext_prop = Property.find_by(name: "ext", table_object_id: obj.id)
														ext_prop.value = ext

														if !ext_prop.save
															errors.push(Array.new([1103, "Unknown validation error"]))
															status = 500
														end
													end

													# Check if the user has enough free storage
													file_size = get_file_size(request.body)
													free_storage = get_total_storage_of_user(user.id) - get_used_storage_of_user(user.id)

													if free_storage < file_size
														errors.push(Array.new([1110, "Not enough storage space"]))
														status = 400
													end
													
													
													if !obj.save
														errors.push(Array.new([1103, "Unknown validation error"]))
														status = 500
													else
														begin
															# Upload new file
															upload_blob(app.id, obj.id, request.body)
														rescue Exception => e
															errors.push(Array.new([1103, "Unknown validation error"]))
															status = 500
														end

														if errors.length == 0
															size_prop = Property.new(table_object_id: obj.id, name: "size", value: file_size)

															if !size_prop.save
																errors.push(Array.new([1103, "Unknown validation error"]))
																status = 500
															else
																@result = obj.attributes

																properties = Hash.new
																obj.properties.each do |prop|
																	properties[prop.name] = prop.value
																end
			
																@result["properties"] = properties
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
   
   def delete_object
		object_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  obj = TableObject.find_by_id(object_id)

						if !obj
							obj = TableObject.find_by(uuid: object_id)
						end
               
                  if !obj
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
                  else
                     table = Table.find_by_id(obj.table_id)
                  
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
                     else
                        app = App.find_by_id(table.app_id)
                     
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
                        else
									if (app.dev_id != dev.id)    # Check if the app belongs to the dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
                           else
                              # Check if user owns the object
										if obj.user_id != user.id
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											# Delete the file if it exists
											delete_blob(app.id, obj.id)

                                 obj.destroy!
                                 @result = {}
                                 ok = true
                                 
                                 # Save that user does not use the app if this was the last object
                                 if TableObject.find_by(user_id: user.id).nil?
                                    users_app = UsersApp.find_by(user_id: user.id, app_id: app.id)
                                    users_app.destroy!
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
      
      if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   # Table methods
   define_method :create_table do
      table_name = params["table_name"]
      app_id = params["app_id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([2113, "Missing field: table_name"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  app = App.find_by_id(app_id)
                  # Check if the app exists
                  if !app
                     errors.push(Array.new([2803, "Resource does not exist: App"]))
                     status = 400
                  else
                     if !(((dev == Dev.first) && (app.dev == user.dev)) || (user.dev == dev) && (app.dev == user.dev))  # Von Webseite oder als Dev & Nutzer
                        errors.push(Array.new([1102, "Action not allowed"]))
                        status = 403
                     else
                        table = Table.find_by(name: table_name, app_id: app.id)
                        
                        if table
                           errors.push(Array.new([2904, "Resource already exists: Table"]))
                           status = 202
                        else
                           # Check if table_name is too long or too short
                           if table_name.length > max_table_name_length
                              errors.push(Array.new([2305, "Field too long: table_name"]))
                              status = 400
                           end
                           
                           if table_name.length < min_table_name_length
                              errors.push(Array.new([2205, "Field too short: table_name"]))
                              status = 400
                           end
                           
                           if table_name.include? " "
                              errors.push(Array.new([2501, "Field contains not allowed characters: table_name"]))
                              status = 400
                           end
                           
                           if errors.length == 0
                              # Create the new table and return it
                              table = Table.new(name: (table_name[0].upcase + table_name[1..-1]), app_id: app.id)
                              if !table.save
                                 errors.push(Array.new([1103, "Unknown validation error"]))
                                 status = 500
                              else
                                 @result = table
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
         status = 201
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
   end
   
   def get_table
      app_id = params["app_id"]
      table_name = params["table_name"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !app_id
         errors.push(Array.new([2110, "Missing field: app_id"]))
         status = 400
      end
      
      if !table_name || table_name.length < 1
         errors.push(Array.new([2113, "Missing field: table_name"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  app = App.find_by_id(app_id)
                  # Check if the app exists
                  if !app
                     errors.push(Array.new([2803, "Resource does not exist: App"]))
                     status = 400
                  else
                     table = Table.find_by(name: table_name, app_id: app.id)
                     # Check if the table exists
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 404
                     else
                        # Jeder kann zugreifen, solange die App dem Dev gehört oder man auf eigene Tabellen von der Webseite zugreift
                        if !(((dev == Dev.first) && (app.dev == user.dev)) || app.dev == dev)
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           @result = table.attributes
                           
                           array = Array.new
                           
                           table.table_objects.each do |table_object|
                              if table_object.user_id == user.id
                                 object = Hash.new
											object["id"] = table_object.id
											object["uuid"] = table_object.uuid
											object["user_id"] = table_object.user_id
                                 
                                 table_object.properties.each do |property|
                                    object[property.name] = property.value
                                 end
                                 array.push(object)
                              end
                           end
                           
                           @result["entries"] = array
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
   
   define_method :update_table do
      table_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_id
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  table = Table.find_by_id(table_id)
               
                  if !table
                     errors.push(Array.new([2804, "Resource does not exist: Table"]))
                     status = 400
                  else
                     app = App.find_by_id(table.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this is only called from the website
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
                                 # Validate the table name
                                 if name.length > max_table_name_length
                                    errors.push(Array.new([2303, "Field too long: name"]))
                                    status = 400
                                 end
                                 
                                 if name.length < min_table_name_length
                                    errors.push(Array.new([2203, "Field too short: name"]))
                                    status = 400
                                 end
                                 
                                 if name.include? " "
                                    errors.push(Array.new([2501, "Field contains not allowed characters: table_name"]))
                                    status = 400
                                 end
                              end
                              
                              if errors.length == 0
                                 table.name = (name[0].upcase + name[1..-1])
                              end
                           end
                           
                           if errors.length == 0
                              # Update the table and send it back
                              if !table.save
                                 errors.push(Array.new([1103, "Unknown validation error"]))
                                 status = 500
                              else
                                 @result = table
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
   
   def delete_table
      table_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !table_id
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  table = Table.find_by_id(table_id)
                  
                  if !table
                     errors.push(Array.new([2804, "Resource does not exist: Table"]))
                     status = 400
                  else
                     app = App.find_by_id(table.app_id)
                     
                     if !app
                        errors.push(Array.new([2803, "Resource does not exist: App"]))
                        status = 400
                     else
                        # Make sure this gets only called from the website
                        if !((dev == Dev.first) && (app.dev == user.dev))
                           errors.push(Array.new([1102, "Action not allowed"]))
                           status = 403
                        else
                           # Delete the table
                           table.destroy!
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
   
   def create_access_token
      object_id = params["id"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
               else
                  # Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
                  else
                     table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
                     else
                        app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
                        else
                           if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
                           else
                              if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = AccessToken.new(token: generate_token)

											if !access_token.save
												errors.push(Array.new([1103, "Unknown validation error"]))
                                    status = 500
											else
												if errors.length == 0
													relation = TableObjectsAccessToken.new(table_object_id: object.id, access_token_id: access_token.id)

													if !relation.save
														errors.push(Array.new([1103, "Unknown validation error"]))
														status = 500
													else
														@result = access_token.attributes
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
            end
         end
      end
      
      if ok && errors.length == 0
         status = 201
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
	end
	
	def add_access_token_to_object
		object_id = params["id"]
		token = params["token"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
		end
		
		if !token || token.length < 1
			errors.push(Array.new([2117, "Missing field: access_token"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						# Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
						else
							table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
							else
								app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
								else
									if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
									else
										if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = AccessToken.find_by(token: token)

											if !access_token
												errors.push(Array.new([2809, "Resource does not exist: AccessToken"]))
                           			status = 400
											else
												# Add access token relationship to object
												relation = TableObjectsAccessToken.new(table_object_id: object.id, access_token_id: access_token.id)

												if !relation.save
													errors.push(Array.new([1103, "Unknown validation error"]))
													status = 500
												else
													@result = access_token.attributes
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

	def remove_access_token_from_object
		object_id = params["id"]
		token = params["token"]
      
      jwt = request.headers['HTTP_AUTHORIZATION'].to_s.length < 2 ? params["jwt"].to_s.split(' ').last : request.headers['HTTP_AUTHORIZATION'].to_s.split(' ').last
      
      errors = Array.new
      @result = Hash.new
      ok = false
      
      if !object_id
         errors.push(Array.new([2103, "Missing field: id"]))
         status = 400
		end
		
		if !token || token.length < 1
			errors.push(Array.new([2117, "Missing field: access_token"]))
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
               
               if !dev     # Check if the dev exists
                  errors.push(Array.new([2802, "Resource does not exist: Dev"]))
                  status = 400
					else
						# Check if the object belongs to the user
                  object = TableObject.find_by_id(object_id)
                  
                  if !object
                     errors.push(Array.new([2805, "Resource does not exist: TableObject"]))
                     status = 400
						else
							table = Table.find_by_id(object.table_id)
                     
                     if !table
                        errors.push(Array.new([2804, "Resource does not exist: Table"]))
                        status = 400
							else
								app = App.find_by_id(table.app_id)
                        
                        if !app
                           errors.push(Array.new([2803, "Resource does not exist: App"]))
                           status = 400
								else
									if app.dev != dev
                              errors.push(Array.new([1102, "Action not allowed"]))
                              status = 403
									else
										if object.user != user
                                 errors.push(Array.new([1102, "Action not allowed"]))
                                 status = 403
										else
											access_token = AccessToken.find_by(token: token)

											if !access_token
												errors.push(Array.new([2809, "Resource does not exist: AccessToken"]))
                           			status = 400
											else
												# Find access token relationship with object
												relation = TableObjectsAccessToken.find_by(table_object_id: object.id, access_token_id: access_token.id)

												if relation
													relation.destroy!
												end

												# If the access token belongs to no objects, destroy it
												if access_token.table_objects.length == 0
													access_token.destroy!
												end

												@result = access_token.attributes
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
		end

		if ok && errors.length == 0
         status = 200
      else
         @result.clear
         @result["errors"] = errors
      end
      
      render json: @result, status: status if status
	end
   
   
   private
   def generate_token
      SecureRandom.hex(20)
   end
end