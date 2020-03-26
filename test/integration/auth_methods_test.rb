require 'test_helper'

class AuthMethodsTest < ActionDispatch::IntegrationTest

   setup do
      save_users_and_devs
   end
   
   # Login tests
   test "Can login" do
		sherlock = users(:sherlock)
		password = "sherlocked"

      get "/v1/auth/login?email=#{sherlock.email}&password=#{password}", headers: {'Authorization' => generate_auth_token(devs(:sherlock))} 
      assert_response 200
   end
   
   test "Can't login without email" do
      get "/v1/auth/login?password=sherlocked", headers: {'Authorization' => generate_auth_token(devs(:sherlock))}
      assert_response 400
   end
   
   test "Can't login without password" do
      get "/v1/auth/login?email=sherlock@web.de", headers: {'Authorization' => generate_auth_token(devs(:sherlock))}
      assert_response 400
   end
   
   test "Can't login without auth" do
      get "/v1/auth/login?email=sherlock@web.de&password=sherlocked"
      assert_response 401
   end
   
   test "Can login without being the dev" do
		sherlock = users(:sherlock)
		password = "sherlocked"

      get "/v1/auth/login?email=#{sherlock.email}&password=#{password}", headers: {'Authorization' => generate_auth_token(devs(:matt))}
      assert_response 200
   end
   
   test "Can login without being confirmed" do
      matt = users(:matt)
      matt.confirmed = false
      matt.save
      
      get "/v1/auth/login?email=#{matt.email}&password=schachmatt", headers: {'Authorization' => generate_auth_token(devs(:matt))}
      resp = JSON.parse response.body
      
		assert_response 200
		assert_not_nil(resp["jwt"])
   end
   
   test "Can't login with an incorrect password" do
		matt = users(:matt)

      get "/v1/auth/login?email=#{matt.email}&password=falschesPassword", headers: {'Authorization' => generate_auth_token(devs(:matt))}
      resp = JSON.parse response.body
      
      assert_response 401
      assert_equal(resp["errors"][0][0], 1201)
   end
   
   test "Can't login with an invalid auth token" do
		matt = users(:matt)
      dev = devs(:matt)
      auth = dev.api_key + "," + Base64.strict_encode64(Base64.strict_encode64(OpenSSL::HMAC.digest(OpenSSL::Digest.new('sha256'), dev.secret_key, dev.uuid)))
      
      get "/v1/auth/login?email=#{matt.email}&password=schachmatt", headers: {'Authorization' => auth}
      resp = JSON.parse response.body
      
      assert_response 401
      assert_equal(resp["errors"][0][0], 1101)
   end
   
   test "Dev does not exist in login" do
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      matt = users(:matt)
      matt.save
      
      sherlock = devs(:sherlock)
      sherlock.destroy!
      
      get "/v1/auth/login?email=#{matt.email}&password=schachmatt", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_equal(resp["errors"][0][0], 2802)
   end
   # End login tests
   
   # login_by_jwt tests
   test "Missing fields in login_by_jwt" do
      get "/v1/auth/login_by_jwt"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(resp["errors"][0][0], 2102)
      assert_equal(resp["errors"][1][0], 2118)
   end

   test "Can't login by jwt from outside the website" do
      matt_dev = devs(:matt)
      cato = users(:cato)
      cato_jwt = (JSON.parse login_user(cato, "123456", matt_dev).body)["jwt"]

      get "/v1/auth/login_by_jwt?api_key=#{matt_dev.api_key}", headers: {'Authorization' => cato_jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(resp["errors"][0][0], 1102)
   end

   test "Can login by jwt" do
      matt_dev = devs(:matt)
      cato = users(:cato)
      website_jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]

      get "/v1/auth/login_by_jwt?api_key=#{matt_dev.api_key}", headers: {'Authorization' => website_jwt}
      resp = JSON.parse response.body

      assert_response 200

      app_jwt = resp["jwt"]

      # Use this jwt to try to access resources that are only accessible by the first dev
      get "/v1/apps/table?app_id=#{apps(:Cards).id}&table_name=#{tables(:card).name}", headers: {'Authorization' => website_jwt}
      resp2 = JSON.parse response.body
      
      assert_response 200
      
      get "/v1/apps/table?app_id=#{apps(:Cards).id}&table_name=#{tables(:card).name}", headers: {'Authorization' => app_jwt}
      resp3 = JSON.parse response.body
      
      assert_response 403
      assert_equal(resp3["errors"][0][0], 1102)
   end
   # End login_by_jwt tests
   
   # Signup tests
   test "Missing fields in signup" do
      post "/v1/auth/signup"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2101, resp["errors"][0][0])
      assert_equal(2105, resp["errors"][1][0])
      assert_equal(2106, resp["errors"][2][0])
      assert_equal(2107, resp["errors"][3][0])
   end
   
   test "Email already taken in signup" do
		sherlock_auth_token = generate_auth_token(devs(:sherlock))
		email = users(:cato).email
      
      post "/v1/auth/signup?email=#{email}&password=testtest&username=test", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2702, resp["errors"][0][0])
   end
   
   test "Username already taken in signup" do
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
		username = users(:cato).username
      
      post "/v1/auth/signup?email=test@example.com&password=testtest&username=#{username}", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2701, resp["errors"][0][0])
   end
   
   test "Can't signup with too short username and password" do
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/auth/signup?email=test@example.com&password=te&username=t", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2201, resp["errors"][0][0])
      assert_equal(2202, resp["errors"][1][0])
   end
   
   test "Can't signup with too long username and password" do
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/auth/signup?email=test@example.com&password=#{"n"*50}&username=#{"n"*30}", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2301, resp["errors"][0][0])
      assert_equal(2302, resp["errors"][1][0])
   end
   
   test "Can't signup with invalid email" do
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/auth/signup?email=testexample&password=testtest&username=testuser", headers: {'Authorization' => sherlock_auth_token}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2401, resp["errors"][0][0])
   end
   
   test "Can't signup from outside the website" do
      matts_auth_token = generate_auth_token(devs(:matt))
      
      post "/v1/auth/signup?email=testexample&password=testtest&username=testuser", headers: {'Authorization' => matts_auth_token}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can successfully sign up" do
		matts_auth_token = generate_auth_token(devs(:sherlock))
		email = "test@example.com"
		password = "testtest"
		username = "testuser"
      
      post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}", headers: {'Authorization' => matts_auth_token}
      resp = JSON.parse response.body
      
		assert_response 201
		assert_not_nil(resp["jwt"])
		assert_equal(email, resp["email"])
		assert_equal(username, resp["username"])
	end
	
	test "Can sign up with session" do
		auth = generate_auth_token(devs(:sherlock))
		email = "test@dav-apps.tech"
		password = "password"
		username = "testuser-12312"
		app = apps(:TestApp)
		dev = devs(:matt)
		device_name = "TestDevice"
		device_type = "Laptop"
		device_os = "Windows"

		post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}&app_id=#{app.id}",
				headers: {'Authorization' => auth},
				params: {api_key: dev.api_key, device_name: device_name, device_type: device_type, device_os: device_os}.to_json
		resp = JSON.parse response.body
		
		assert_response 201

		assert_equal(email, resp["email"])
		assert_equal(username, resp["username"])

		jwt = resp['jwt']
		session_id = jwt.split('.').last.to_i
		session = Session.find_by_id(session_id)

		assert_not_nil(session)
		assert_equal(resp["id"], session.user_id)
		assert_equal(app.id, session.app_id)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
	end

	test "Can't signup with session without api key and device info" do
		auth = generate_auth_token(devs(:sherlock))
		email = "testtest@dav-apps.tech"
		password = "password"
		username = "testuser-234234"
		app = apps(:TestApp)

		post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}&app_id=#{app.id}",
				headers: {'Authorization' => auth}
		resp = JSON.parse response.body

		assert_response 400
		assert_equal(2118, resp["errors"][0][0])
		assert_equal(2125, resp["errors"][1][0])
		assert_equal(2126, resp["errors"][2][0])
		assert_equal(2127, resp["errors"][3][0])
	end

	test "Can't signup with session with the app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		email = "test@dav-apps.tech"
		password = "password"
		username = "testuser-12312"
		app = apps(:davApp)
		dev = devs(:matt)
		device_name = "TestDevice"
		device_type = "Laptop"
		device_os = "Windows"

		post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}&app_id=#{app.id}",
				headers: {'Authorization' => auth},
				params: {api_key: dev.api_key, device_name: device_name, device_type: device_type, device_os: device_os}.to_json
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't signup with session with the api key of a dev that does not exist" do
		auth = generate_auth_token(devs(:sherlock))
		email = "test@dav-apps.tech"
		password = "password"
		username = "testuser-12312"
		app = apps(:TestApp)
		device_name = "TestDevice"
		device_type = "Laptop"
		device_os = "Windows"

		post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}&app_id=#{app.id}",
				headers: {'Authorization' => auth},
				params: {api_key: "blablabla", device_name: device_name, device_type: device_type, device_os: device_os}.to_json
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2802, resp["errors"][0][0])
	end

	test "Can't signup with session with an app that does not exist" do
		auth = generate_auth_token(devs(:sherlock))
		email = "test@dav-apps.tech"
		password = "password"
		username = "testuser-12312"
		dev = devs(:matt)
		device_name = "TestDevice"
		device_type = "Laptop"
		device_os = "Windows"

		post "/v1/auth/signup?email=#{email}&password=#{password}&username=#{username}&app_id=-20",
				headers: {'Authorization' => auth},
				params: {api_key: dev.api_key, device_name: device_name, device_type: device_type, device_os: device_os}.to_json
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end
   # End signup tests

   # create_session tests
   test "Missing fields in create_session" do
		post "/v1/auth/session", headers: {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(2101, resp["errors"][0][0])
		assert_equal(2106, resp["errors"][1][0])
		assert_equal(2107, resp["errors"][2][0])
		assert_equal(2110, resp["errors"][3][0])
		assert_equal(2118, resp["errors"][4][0])
		assert_equal(2125, resp["errors"][5][0])
		assert_equal(2126, resp["errors"][6][0])
		assert_equal(2127, resp["errors"][7][0])
	end
	
	test "Can't create a session when using another Content-Type than application/json" do
		auth_token = generate_auth_token(devs(:matt))

		post "/v1/auth/session", headers: {'Authorization' => auth_token, 'Content-Type' => 'application/xml'}
		resp = JSON.parse response.body

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create a session with invalid auth" do
		auth_token = generate_auth_token(devs(:matt)) + "asd"
		matt = users(:matt)
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => apps(:TestApp).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(1101, resp["errors"][0][0])
	end

	test "Can't create a session from outside the website" do
		auth_token = generate_auth_token(devs(:matt))
		matt = users(:matt)
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => apps(:TestApp).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create a session for a dev that does not exist" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => "asdasdasd", "app_id" => apps(:TestApp).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2802, resp["errors"][0][0])
	end

	test "Can't create a session for an app that does not exist" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => -20, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can't create a session for an app that does not belong to the dev" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => apps(:Cards).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create a session for a user that does not exist" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => "bla@example.com", "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => apps(:TestApp).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't create a session for a user with the wrong password" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "asdasdasd", "api_key" => matt_dev.api_key, "app_id" => apps(:TestApp).id, "device_name" => "Surface Book", "device_type" => "Laptop", "device_os" => "Windows 10"}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(1201, resp["errors"][0][0])
	end

	test "Can create a session" do
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		user_id = matt.id
		app_id = apps(:TestApp).id
		device_name = "Surface Book"
		device_type = "Laptop"
		device_os = "Windows 10"

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => app_id, "device_name" => device_name, "device_type" => device_type, "device_os" => device_os}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 201

		session = Session.find_by_id(resp["id"])
		assert_not_nil(session)
		assert_equal(user_id, session.user_id)
		assert_equal(app_id, session.app_id)
		assert_equal(device_name, session.device_name)
		assert_equal(device_type, session.device_type)
		assert_equal(device_os, session.device_os)
	end
	# End create_session tests
	
	# create_session_with_jwt tests
	test "Missing fields in create_session_with_jwt" do
		post "/v1/auth/session/jwt"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create session with jwt without device info" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)
		api_key = devs(:matt).api_key

		post "/v1/auth/session/jwt",
				headers: {Authorization: jwt, 'Content-Type': 'application/json'},
				params: {app_id: app.id, api_key: api_key}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2125, resp["errors"][0][0])
		assert_equal(2126, resp["errors"][1][0])
		assert_equal(2127, resp["errors"][2][0])
	end

	test "Can't create session with jwt without content type json" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/auth/session/jwt", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create session with jwt from outside the website" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
		api_key = devs(:matt).api_key

		post "/v1/auth/session/jwt", 
				headers: {Authorization: jwt, 'Content-Type': 'application/json'},
				params: {app_id: 1, api_key: api_key, device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create session with jwt for dev that does not exist" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/auth/session/jwt",
				headers: {Authorization: jwt, "Content-Type": 'application/json'},
				params: {app_id: app.id, api_key: "blablabla", device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"}.to_json
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2802, resp["errors"][0][0])
	end

	test "Can't create session with jwt for app that does not exist" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
		api_key = devs(:matt).api_key

		post "/v1/auth/session/jwt",
				headers: {Authorization: jwt, "Content-Type": 'application/json'},
				params: {app_id: -20, api_key: api_key, device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"}.to_json
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can't create session with jwt for app that does not belong to the dev" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
		api_key = devs(:matt).api_key
		app = apps(:Cards)

		post "/v1/auth/session/jwt",
				headers: {Authorization: jwt, 'Content-Type': 'application/json'},
				params: {app_id: app.id, api_key: api_key, device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can create session with jwt" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)
		api_key = devs(:matt).api_key

		post "/v1/auth/session/jwt",
				headers: {Authorization: jwt, 'Content-Type': 'application/json'},
				params: {app_id: app.id, api_key: api_key, device_name: "Surface Book", device_type: "Laptop", device_os: "Windows 10"}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
	end
	# End create_sesion_with_jwt tests

   # get_session tests
   test "Missing fields in get_session" do
      session = sessions(:CatoTestAppSession)

      get "/v1/auth/session/#{session.id}"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get session with invalid jwt" do
      session = sessions(:CatoTestAppSession)

      get "/v1/auth/session/#{session.id}", headers: {"Authorization" => "asdasdasd"}
      resp = JSON.parse response.body

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end
	
	test "Can't get session from outside the website" do
		session = sessions(:CatoTestAppSession)
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/auth/session/#{session.id}", headers: {"Authorization" => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get session that does not exist" do
		jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/session/-12", headers: {"Authorization" => jwt}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2814, resp["errors"][0][0])
	end

	test "Can't get the session of another user" do
		session = sessions(:CatoTestAppSession)
		jwt = (JSON.parse login_user(users(:sherlock), "sherlocked", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/session/#{session.id}", headers: {"Authorization" => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get session" do
		session = sessions(:CatoTestAppSession)
		jwt = (JSON.parse login_user(users(:cato), "123456", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/session/#{session.id}", headers: {"Authorization" => jwt}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(session.id, resp["id"])
		assert_equal(session.user_id, resp["user_id"])
		assert_equal(session.app_id, resp["app_id"])
		assert_equal(session.exp.to_i, resp["exp"])
		assert_equal(session.device_name, resp["device_name"])
		assert_equal(session.device_type, resp["device_type"])
		assert_equal(session.device_os, resp["device_os"])
	end
   # End get_session tests
   
	# delete_session tests
	test "Missing fields in delete_session" do
		delete "/v1/auth/session"
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't delete a session that does not exist" do
		# Create a session
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		user_id = matt.id
		app_id = apps(:TestApp).id
		device_name = "Surface Book"
		device_type = "Laptop"
		device_os = "Windows 10"

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => app_id, "device_name" => device_name, "device_type" => device_type, "device_os" => device_os}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 201

		# Delete the session
		session = Session.find_by_id(resp["id"])
		session.destroy!
		
		session = Session.find_by_id(resp["id"])
		assert_nil(session)

		# Try to delete the session through the endpoint
		delete "/v1/auth/session", headers: {'Authorization' => resp["jwt"]}
		resp2 = JSON.parse response.body

		assert_response 404
		assert_equal(2814, resp2["errors"][0][0])
	end

	test "Can delete a session" do
		# Create a session
		auth_token = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt_dev = devs(:matt)

		user_id = matt.id
		app_id = apps(:TestApp).id
		device_name = "Surface Book"
		device_type = "Laptop"
		device_os = "Windows 10"

		post "/v1/auth/session", 
				params: {"email" => matt.email, "password" => "schachmatt", "api_key" => matt_dev.api_key, "app_id" => app_id, "device_name" => device_name, "device_type" => device_type, "device_os" => device_os}.to_json,
				headers: {'Authorization' => auth_token, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 201

		# Delete the session
		delete "/v1/auth/session", headers: {'Authorization' => resp["jwt"]}
		resp = JSON.parse response.body

		assert_response 200

		session = Session.find_by_id(resp["id"])
		assert_nil(session)
	end
	# End delete_session tests

	# get_user tests
	test "Missing fields in get_user" do
		get "/v1/auth/user/#{users(:sherlock).id}"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get user with invalid jwt" do
		get "/v1/auth/user/#{users(:sherlock).id}", headers: {Authorization: "blablabla"}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't get user that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		get "/v1/auth/user/-123", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't get different user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/user/#{users(:sherlock).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/auth/user/#{matt.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end

		[
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_nil(resp[key])
		end
	end

	test "Can get user with all information with jwt of the first dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		# Save values for period_end and stripe_customer_id
		matt.period_end = DateTime.now
		matt.stripe_customer_id = "Hello World"
		matt.save

		get "/v1/auth/user/#{matt.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan",
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end
	end

	test "Can get user with session jwt" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:dav), apps(:davApp).id, "schachmatt")

		get "/v1/auth/user/#{matt.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end

		[
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_nil(resp[key])
		end
	end

	test "Can get user with all information with session jwt of the first dev" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")

		# Save values for period_end and stripe_customer_id
		matt.period_end = DateTime.now
		matt.stripe_customer_id = "Hello World"
		matt.save

		get "/v1/auth/user/#{matt.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan",
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end
	end
	# End get_user tests
	
	# get_user_by_auth tests
	test "Missing fields in get_user_by_auth" do
		get "/v1/auth/user/#{users(:sherlock).id}/auth"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't get user by auth with invalid auth" do
		get "/v1/auth/user/#{users(:sherlock).id}/auth", headers: {Authorization: "asdasd,asdasd"}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1101, resp["errors"][0][0])
	end

	test "Can't get user by auth that does not exist" do
		auth_token = generate_auth_token(devs(:sherlock))

		get "/v1/auth/user/-12/auth", headers: {Authorization: auth_token}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't get user by auth from outside the website" do
		matt = users(:matt)
		auth_token = generate_auth_token(devs(:matt))

		get "/v1/auth/user/#{matt.id}/auth", headers: {Authorization: auth_token}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get user by auth" do
		matt = users(:matt)
		auth_token = generate_auth_token(devs(:sherlock))

		get "/v1/auth/user/#{matt.id}/auth", headers: {Authorization: auth_token}
		resp = JSON.parse(response.body)

		assert_response 200

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan",
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end
	end
	# End get_user_by_auth tests

   # get_user_by_jwt tests
   test "Missing fields in get_user_by_jwt" do
      get "/v1/auth/user"
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get user with jwt with invalid jwt" do
      get "/v1/auth/user", headers: {Authorization: "blablabla"}
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(1302, resp["errors"][0][0])
	end

	test "Can get user with jwt" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/auth/user", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end

		[
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_nil(resp[key])
		end
	end

	test "Can get user with jwt with all information with jwt of the first dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		# Save values for period_end and stripe_customer_id
		matt.period_end = DateTime.now
		matt.stripe_customer_id = "Hello World"
		matt.save

		get "/v1/auth/user", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan",
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end
	end

	test "Can get user with jwt with session jwt" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:dav), apps(:davApp).id, "schachmatt")

		get "/v1/auth/user", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end

		[
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_nil(resp[key])
		end
	end

	test "Can get user with jwt with all information with session jwt of the first dev" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")

		# Save values for period_end and stripe_customer_id
		matt.period_end = DateTime.now
		matt.stripe_customer_id = "Hello World"
		matt.save

		get "/v1/auth/user", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		[
			"id",
			"email",
			"username",
			"confirmed",
			"created_at",
			"updated_at",
			"plan",
			"old_email",
			"new_email",
			"period_end",
			"subscription_status",
			"stripe_customer_id"
		].each do |key|
			assert_equal(matt[key], resp[key])
		end

		assert(resp["dev"])
		assert(!resp["provider"])
	end

   test "Can get user with jwt and used storage of apps" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      file1Path = "test/fixtures/files/test.png"

		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&ext=png", 
				params: File.open(file1Path, "rb").read, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'image/png'}
      resp = JSON.parse response.body

      assert_response 201

      get "/v1/auth/user", headers: {'Authorization' => jwt}
      resp2 = JSON.parse response.body

      assert_response 200
      assert_equal(File.size(file1Path), resp2["apps"][0]["used_storage"])

      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
	end
   # End get_user_by_jwt tests
   
   # update_user tests
   test "Can't use another content type but json in update_user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end
   
   test "Can't update user from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
      
   test "Can't update user with invalid email" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {email: "testemail"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2401, resp["errors"][0][0])
   end
   
   test "Can't update user with too short username" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {username: "d"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2201, resp["errors"][0][0])
   end
   
   test "Can't update user with too long username" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {username: "#{'d' * 30}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2301, resp["errors"][0][0])
   end
   
   test "Can't update user with username that's already taken" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {username: "cato"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2701, resp["errors"][0][0])
   end
   
   test "Can't update user with too short password" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {password: "c"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2202, resp["errors"][0][0])
   end
   
   test "Can't update user with too long password" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {password: "#{'n' * 40}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2302, resp["errors"][0][0])
   end
   
   test "Can update new_password in update_user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      old_new_password = matt.new_password
      new_password = "testpassword"
      
		put "/v1/auth/user", 
            params: {password: new_password}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      matt = User.find_by_id(matt.id)
      
      assert_response 200
      assert_not_nil(matt.new_password)
      assert_not_equal(old_new_password, matt.new_password)
      assert_not_equal(new_password, matt.new_password)
   end
   
   test "Can update email in update_user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {email: "test14@example.com"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      matt = User.find_by_id(matt.id)

      assert_response 200
      assert_equal(resp["new_email"], matt.new_email)
   end
   
   test "Can update username in update_user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {username: "newtestuser"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      matt = User.find_by_id(matt.id)
      
      assert_response 200
      assert_equal(resp["username"], matt.username)
   end
   
   test "Can update email and password of user at once" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
            params: {email: "newemail@test.com", password: "hello password"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      matt = User.find_by_id(matt.id)
      
      assert_response 200
      assert_equal(resp["new_email"], matt.new_email)
   end
   
   test "Can see apps of the user in update_user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", 
            params: {page1: "Hello World", page2: "Hallo Welt"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
		put "/v1/auth/user", 
            params: {email: "newemail@test.com", password: "hello password"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(apps(:Cards).id, resp2["apps"][0]["id"])
	end
	
   test "Can upload an avatar and the etag updates in update_user" do
      avatarPath = "test/fixtures/files/test.png"
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      get "/v1/auth/user/#{matt.id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 200
      avatar_etag = resp["avatar_etag"]

      avatar = File.open(avatarPath, "rb")
      avatar_content = Base64.encode64(avatar.read)

		put "/v1/auth/user", 
				params: {avatar: avatar_content}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp2 = JSON.parse response.body
      avatar_etag2 = resp2["avatar_etag"]

      assert_response 200
      assert(avatar_etag != avatar_etag2)
   end
	# End update_user tests
	
	# create_stripe_customer_for_user tests
	test "Missing fields in create_stripe_customer_for_user" do
		post "/v1/auth/user/stripe"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create stripe customer for user with invalid jwt" do
		post "/v1/auth/user/stripe", headers: {Authorization: 'blablabla'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create stripe customer for user from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:matt)).body))["jwt"]

		post "/v1/auth/user/stripe", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create stripe customer for user that already is stripe customer" do
		torera = users(:torera)
		jwt = (JSON.parse(login_user(torera, "Geld", devs(:sherlock)).body))["jwt"]

		post "/v1/auth/user/stripe", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1115, resp["errors"][0][0])
	end

	test "Can create stripe customer for user with stripe customer that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]
		matt.stripe_customer_id = "blablabla"
		matt.save

		post "/v1/auth/user/stripe", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201

		# Get the user and check if the stripe_customer_id matches the stripe_customer_id in the result
		matt = User.find_by_id(matt.id)
		assert_equal(matt.stripe_customer_id, resp["stripe_customer_id"])

		# Get the stripe customer and delete it
		customer = Stripe::Customer.retrieve(matt.stripe_customer_id)
		customer.delete
	end

	test "Can create stripe customer for user" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/auth/user/stripe", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201

		# Get the user and check if the stripe_customer_id matches the stripe_customer_id in the result
		matt = User.find_by_id(matt.id)
		assert_equal(matt.stripe_customer_id, resp["stripe_customer_id"])

		# Get the stripe customer and delete it
		customer = Stripe::Customer.retrieve(matt.stripe_customer_id)
		customer.delete
	end
	# End create_stripe_customer_for_user tests
   
   # delete_user tests
   test "Missing fields in delete_user" do
      tester = users(:tester2)

      delete "/v1/auth/user/#{tester.id}"
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(2101, resp["errors"][0][0])
   end

	test "Can't delete user from outside the website" do
		auth = generate_auth_token(devs(:matt))
		tester = users(:tester2)

		delete "/v1/auth/user/#{tester.id}",
				params: {email_confirmation_token: tester.email_confirmation_token, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't delete user without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester2)

		delete "/v1/auth/user/#{tester.id}",
				params: {email_confirmation_token: tester.email_confirmation_token, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

   test "Can't delete user with incorrect confirmation tokens" do
		auth = generate_auth_token(devs(:sherlock))
      tester = users(:tester2)

      delete "/v1/auth/user/#{tester.id}",
				params: {email_confirmation_token: "blabla", password_confirmation_token: "blablabla"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)
      
      assert_response 400
      assert_equal(1204, resp["errors"][0][0])
   end
   
   test "Can delete user" do
		auth = generate_auth_token(devs(:sherlock))
      tester = users(:tester2)

      delete "/v1/auth/user/#{tester.id}",
				params: {email_confirmation_token: tester.email_confirmation_token, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)
		
      assert_response 200
   end
   # End delete_user tests

   # remove_app tests
   test "Missing fields in remove_app" do
      delete "/v1/auth/app/1"
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(2101, resp["errors"][0][0])
   end

	test "Can't remove app from outside the website" do
		auth = generate_auth_token(devs(:matt))
      tester = users(:tester2)
		app = apps(:TestApp)

		delete "/v1/auth/app/#{app.id}", 
				params: {user_id: tester.id, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization' => auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

	test "Can't remove app without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester2)
		app = apps(:TestApp)

		delete "/v1/auth/app/#{app.id}",
				params: {user_id: tester.id, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't remove app that the user does not use" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		app = apps(:davApp)

		delete "/v1/auth/app/#{app.id}",
				params: {user_id: matt.id, password_confirmation_token: matt.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(1114, resp["errors"][0][0])
	end

	test "Can't remove app that does not exist" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester2)

		delete "/v1/auth/app/-123",
				params: {user_id: tester.id, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can't remove app from user that does not exist" do
		auth = generate_auth_token(devs(:sherlock))
		app = apps(:TestApp)

		delete "/v1/auth/app/#{app.id}",
				params: {user_id: -123, password_confirmation_token: "blablabla"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can remove app" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester2)
		app = apps(:TestApp)

		delete "/v1/auth/app/#{app.id}",
				params: {user_id: tester.id, password_confirmation_token: tester.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200
	end
   # End remove_app tests
   
	# confirm_user tests
	test "Missing fields in confirm_user" do
		tester = users(:tester)

		post "/v1/auth/user/#{tester.id}/confirm"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't confirm user from outside the website" do
		auth = generate_auth_token(devs(:matt))
		tester = users(:tester)

		post "/v1/auth/user/#{tester.id}/confirm",
				headers: {'Authorization': auth, 'Content-Type': 'application/json'},
				params: {email_confirmation_token: tester.email_confirmation_token}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't confirm user without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester)

		post "/v1/auth/user/#{tester.id}/confirm",
				headers: {'Authorization': auth, 'Content-Type': 'application/xml'},
				params: {email_confirmation_token: tester.email_confirmation_token}.to_json
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't confirm user that does not exist" do
		auth = generate_auth_token(devs(:sherlock))

		post "/v1/auth/user/-123/confirm",
				headers: {'Authorization': auth, 'Content-Type': 'application/json'},
				params: {email_confirmation_token: "blablabla"}.to_json
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't confirm user with incorrect email confirmation token" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester)

		post "/v1/auth/user/#{tester.id}/confirm",
				headers: {'Authorization': auth, 'Content-Type': 'application/json'},
				params: {email_confirmation_token: "blablablabla"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1204, resp["errors"][0][0])
	end

	test "Can confirm user" do
		auth = generate_auth_token(devs(:sherlock))
		tester = users(:tester)

		post "/v1/auth/user/#{tester.id}/confirm",
				headers: {'Authorization': auth, 'Content-TYpe': 'application/json'},
				params: {email_confirmation_token: tester.email_confirmation_token}.to_json
		resp = JSON.parse(response.body)

		assert_response 200
	end
   # End confirm_user tests
   
   # send_verification_email tests
   test "Missing fields in send_verification_email" do
      post "/v1/auth/send_verification_email"
      resp = JSON.parse(response.body)
      
      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end 
   
   test "Can't send verification email with already confirmed user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/auth/send_verification_email", headers: {'Authorization' => jwt}
      resp = JSON.parse(response.body)
      
      assert_response 400
      assert_equal(1106, resp["errors"][0][0])
	end
	
	test "Can't send verification email from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/auth/send_verification_email", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)
		
		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end
   
   test "Can send verification email" do
      tester = users(:tester)
		jwt = (JSON.parse login_user(tester, "testpassword", devs(:sherlock)).body)["jwt"]
      
      post "/v1/auth/send_verification_email", headers: {'Authorization' => jwt}
      resp = JSON.parse(response.body)
      
      assert_response 200
   end
   # End send_verification_email tests

   # send_delete_account_email tests
   test "Missing fields in send_delete_account_email" do
      post "/v1/auth/send_delete_account_email"
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
	end
	
	test "Can't send delete account email from outside the website" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:matt)).body)["jwt"]

		post "/v1/auth/send_delete_account_email", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

   test "Can send delete account email" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/auth/send_delete_account_email", headers: {'Authorization' => jwt}
      resp = JSON.parse(response.body)
      
      assert_response 200
   end
	# End send_delete_account_email tests
	
	# send_remove_app_email tests
	test "Missing fields in send_remove_app_email" do
		post "/v1/auth/send_remove_app_email"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't send remove app email from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		app = apps(:Cards)

		post "/v1/auth/send_remove_app_email", 
				params: {app_id: app.id}.to_json,
				headers: {'Authorization': jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't send remove app email without content type json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:Cards)

		post "/v1/auth/send_remove_app_email",
				params: {app_id: app.id}.to_json,
				headers: {'Authorization': jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't send remove app email for app that the user does not use" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/auth/send_remove_app_email", 
				params: {app_id: app.id}.to_json,
				headers: {'Authorization': jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(1114, resp["errors"][0][0])
	end

	test "Can't send remove app email for app that does not exist" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		app_id = -123

		post "/v1/auth/send_remove_app_email", 
				params: {app_id: app_id}.to_json,
				headers: {'Authorization': jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can send remove app email" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:Cards)

		post "/v1/auth/send_remove_app_email", 
				params: {app_id: app.id}.to_json,
				headers: {'Authorization': jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200
	end
	# End send_remove_app_Email tests
   
   # send_password_reset_email tests
   test "Missing fields in send_password_reset_email" do
      post "/v1/auth/send_password_reset_email"
      resp = JSON.parse(response.body)
      
      assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end
	
	test "Can't send password reset email from outside the website" do
		matt = users(:matt)
		auth = generate_auth_token(devs(:matt))

		post "/v1/auth/send_password_reset_email?email=#{matt.email}", 
				params: {email: matt.email}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)
		
		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't send password reset email without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)

		post "/v1/auth/send_password_reset_email", 
				params: {email: matt.email}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/xml'}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't send password reset email for user that does not exist" do
		auth = generate_auth_token(devs(:sherlock))

		post "/v1/auth/send_password_reset_email", 
				params: {email: "bla@dav-apps.tech"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end
   
   test "Can send password reset email" do
		matt = users(:matt)
		auth = generate_auth_token(devs(:sherlock))
      
		post "/v1/auth/send_password_reset_email", 
				params: {email: matt.email}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)
      
      assert_response 200
   end
   # End send_reset_password_email tests
   
   # set_password tests
   test "Missing fields in set_password" do
      post "/v1/auth/set_password"
      resp = JSON.parse(response.body)

      assert_response 401
      assert_equal(2101, resp["errors"][0][0])
	end
	
	test "Can't set password without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
      password = "newpassword"

		post "/v1/auth/set_password", 
				params: {user_id: matt.id, password_confirmation_token: matt.password_confirmation_token, password: password}.to_json,
				headers: {'Authorization': auth}
		resp = JSON.parse(response.body)
		
		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set password from outside the website" do
		auth = generate_auth_token(devs(:matt))
		matt = users(:matt)
		password = "newpassword"
		
		post "/v1/auth/set_password", 
				params: {user_id: matt.id, password_confirmation_token: matt.password_confirmation_token, password: password}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't set password for user that does not exist" do
		auth = generate_auth_token(devs(:sherlock))

		post "/v1/auth/set_password", 
				params: {user_id: -123, password_confirmation_token: "blablabla", password: "newpassword"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't set password with incorrect password confirmation token" do
		auth = generate_auth_token(devs(:sherlock))
      matt = users(:matt)
      password = "newpassword"

		post "/v1/auth/set_password", 
				params: {user_id: matt.id, password_confirmation_token: "blabla", password: password}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)

      assert_response 400
      assert_equal(1203, resp["errors"][0][0])
   end

	test "Can set password" do
		auth = generate_auth_token(devs(:sherlock))
      matt = users(:matt)
      password = "newpassword"

		post "/v1/auth/set_password",
				params: {user_id: matt.id, password_confirmation_token: matt.password_confirmation_token, password: password}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)

      assert_response 200
   end
   # End set_password tests

	# save_new_password tests
	test "Missing fields in save_new_password" do
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/save_new_password"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't save new password from outside the website" do
		auth = generate_auth_token(devs(:matt))
		matt = users(:matt)
		
		post "/v1/auth/user/#{matt.id}/save_new_password",
				params: {password_confirmation_token: matt.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't save new password without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		
		post "/v1/auth/user/#{matt.id}/save_new_password",
				params: {password_confirmation_token: matt.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': "application/xml"}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't save new password with incorrect password confirmation token" do
		auth = generate_auth_token(devs(:sherlock))
      matt = users(:matt)
      
		post "/v1/auth/user/#{matt.id}/save_new_password",
				params: {password_confirmation_token: "aasdasdasdad"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)
      
      assert_response 400
      assert_equal(1203, resp["errors"][0][0])
   end
   
	test "Can't save new password with empty new_password" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt.new_password = nil
		matt.save
      
		post "/v1/auth/user/#{matt.id}/save_new_password",
				params: {password_confirmation_token: matt.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
      resp = JSON.parse(response.body)
      
      assert_response 400
      assert_equal(2603, resp["errors"][0][0])
   end
   
	test "Can save new password" do
		auth = generate_auth_token(devs(:sherlock))
      matt = users(:matt)
      
		post "/v1/auth/user/#{matt.id}/save_new_password",
				params: {password_confirmation_token: matt.password_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200
   end
   # End save_new_password tests
   
	# save_new_email tests
	test "Missing fields in save_new_email" do
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/save_new_email"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't save new email from outside the website" do
		auth = generate_auth_token(devs(:matt))
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/save_new_email",
				params: {email_confirmation_token: matt.email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't save new email without content type json" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/save_new_email",
				params: {email_confirmation_token: matt.email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/xml'}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't save new email with incorrect email confirmation token" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		
		post "/v1/auth/user/#{matt.id}/save_new_email",
				params: {email_confirmation_token: "blablabla"}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
      assert_equal(1204, resp["errors"][0][0])
	end

	test "Can't save new email with empty new_email" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt.new_email = nil
		matt.save

		post "/v1/auth/user/#{matt.id}/save_new_email",
				params: {email_confirmation_token: matt.email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
      assert_equal(2601, resp["errors"][0][0])
	end

	test "Can save new email" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		new_email = matt.new_email
		old_email = matt.email
		
		post "/v1/auth/user/#{matt.id}/save_new_email",
				params: {email_confirmation_token: matt.email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		# Check if the new email was saved
		matt = User.find_by_id(matt.id)
		assert_equal(new_email, matt.email)
		assert_equal(old_email, matt.old_email)
		assert_nil(matt.new_email)

		assert_response 200
	end

	test "Can save new email when using stripe" do
		auth = generate_auth_token(devs(:sherlock))
		torera = users(:torera)
		original_email = torera.email

		post "/v1/auth/user/#{torera.id}/save_new_email",
				params: {email_confirmation_token: torera.email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200

		# Check if the email was updated on stripe
		torera = User.find_by_id(torera.id)
		customer = Stripe::Customer.retrieve(torera.stripe_customer_id)
   	assert_equal(torera.email, customer.email)

		# Change the email back to the original email
		email_confirmation_token = "emailconfirmationtoken"
		torera.new_email = original_email
		torera.email_confirmation_token = email_confirmation_token
		torera.save

		post "/v1/auth/user/#{torera.id}/save_new_email",
				params: {email_confirmation_token: email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200

		customer = Stripe::Customer.retrieve(torera.stripe_customer_id)
   	assert_equal(original_email, customer.email)
	end
   # End save_new_email tests
   
   # reset_new_email tests
	test "Missing fields in reset_new_email" do
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/reset_new_email"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't reset new email for user that does not exist" do
		auth = generate_auth_token(devs(:sherlock))

		post "/v1/auth/user/-123/reset_new_email", headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2801, resp["errors"][0][0])
	end

	test "Can't reset new email from outside the website" do
		auth = generate_auth_token(devs(:matt))
		matt = users(:matt)

		post "/v1/auth/user/#{matt.id}/reset_new_email", headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't reset new email with empty old_email" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		matt.old_email = nil
		matt.save

		post "/v1/auth/user/#{matt.id}/reset_new_email", headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2602, resp["errors"][0][0])
	end

	test "Can reset new email" do
		auth = generate_auth_token(devs(:sherlock))
		matt = users(:matt)
		old_email = matt.old_email

		post "/v1/auth/user/#{matt.id}/reset_new_email", headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 200

		# Check if the email fields were updated
		matt = User.find_by_id(matt.id)
		assert_equal(old_email, matt.email)
		assert_nil(matt.old_email)
	end

	test "Can reset new email when using stripe" do
		auth = generate_auth_token(devs(:sherlock))
		torera = users(:torera)
		original_email = torera.email
		old_email = torera.old_email

		post "/v1/auth/user/#{torera.id}/reset_new_email", headers: {'Authorization': auth}
		resp = JSON.parse(response.body)

		assert_response 200

		# Check if the email was updated on stripe
		torera = User.find_by_id(torera.id)
		customer = Stripe::Customer.retrieve(torera.stripe_customer_id)
		assert_equal(torera.email, customer.email)

		# Change the email back to the original email
		email_confirmation_token = "emailconfirmationtoken"
		torera.new_email = original_email
		torera.email_confirmation_token = email_confirmation_token
		torera.save

		post "/v1/auth/user/#{torera.id}/save_new_email", 
				params: {email_confirmation_token: email_confirmation_token}.to_json,
				headers: {'Authorization': auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200

		customer = Stripe::Customer.retrieve(torera.stripe_customer_id)
		assert_equal(original_email, customer.email)
	end
	# End reset_new_email tests
	
	# create_archive tests
	test "Missing fields in create_archive" do
		post "/v1/auth/archive"
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create an archive from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/auth/archive", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end
	# End create_archive tests

	# get_archive tests
	test "Missing fields in get_archive" do
		get "/v1/auth/archive/1"
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get the archive of another user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/archive/#{archives(:SherlocksFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get the archive from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/auth/archive/#{archives(:MattsFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get the archive" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		archive_id = archives(:MattsFirstArchive).id

		get "/v1/auth/archive/#{archive_id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 200
      assert_equal(archive_id, resp["id"])
      assert_equal(archive_parts(:FirstPartOfMattsFirstArchive).id, resp["parts"][0]["id"])
	end

	test "Can't get an archive that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/archive/22", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 404
		assert_equal(2810, resp["errors"][0][0])
	end
	# End get_archive tests

	# get_archive_part tests
	test "Missing fields in get_archive_parts" do
		get "/v1/auth/archive_part/1"
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get the archive_part of the archive of another user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/archive_part/#{archive_parts(:FirstPartOfSherlocksFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get the archive_part from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/auth/archive_part/#{archive_parts(:FirstPartOfMattsFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get the archive_part" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		archive_part_id = archive_parts(:FirstPartOfMattsFirstArchive).id

		get "/v1/auth/archive_part/#{archive_part_id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 200
		assert_equal(archive_part_id, resp["id"])
	end

	test "Can't get an archive_part that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/auth/archive_part/22", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 404
		assert_equal(2811, resp["errors"][0][0])
	end
	# End get_archive_part tests

	# delete_archive tests
	test "Missing fields in delete_archive" do
		delete "/v1/auth/archive/1"
		resp = JSON.parse response.body

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't delete the archive of another user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		delete "/v1/auth/archive/#{archives(:SherlocksFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't delete an archive from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		delete "/v1/auth/archive/#{archives(:MattsFirstArchive).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't delete an archive that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		delete "/v1/auth/archive/22", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2810, resp["errors"][0][0])
	end
	# End delete_archive tests
end
