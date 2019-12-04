require 'test_helper'

class ApisMethodsTest < ActionDispatch::IntegrationTest
	setup do
      save_users_and_devs
	end
	
	# Tests for create_api
	test "Missing fields in create_api" do
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create api without content type json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create api with invalid jwt" do
		jwt = "asdpjasdaksd"
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create api from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api for the app of another dev" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api without name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2111, resp["errors"][0][0])
	end

	test "Can't create api with too short name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "A"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
	end

	test "Can't create api with too long name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "A" * 120}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
	end

	test "Can create api" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)
		name = "Test API"

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_not_nil(resp["id"])
		assert_equal(app.id, resp["app_id"])
		assert_equal(name, resp["name"])
	end

	# Tests for get_api
	test "Missing fields in get_api" do
		api = apis(:TestAppApi)

		get "/v1/api/#{api.id}"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get api with invalid jwt" do
		jwt = "sadasdasd"
		api = apis(:TestAppApi)

		get "/v1/api/#{api.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't get api from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		api = apis(:TestAppApi)

		get "/v1/api/#{api.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get api of the app of another dev" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		api = apis(:TestAppApi)

		get "/v1/api/#{api.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get api" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		api = apis(:TestAppApi)

		get "/v1/api/#{api.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_equal(api.id, resp["id"])
		assert_equal(api.app_id, resp["app_id"])
		assert_equal(api.name, resp["name"])
	end

	# Tests for create_api_endpoint
	test "Missing fields in create_api_endpoint" do
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't create api endpoint without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create api endpoint for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		path = "test"
		method = "GET"
		commands = "(log test)"

		post "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: path, method: method, commands: commands}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api endpoint without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint",
			headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2132, resp["errors"][0][0])
		assert_equal(2133, resp["errors"][1][0])
		assert_equal(2134, resp["errors"][2][0])
	end

	test "Can't create api endpoint with too short properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "a", method: "GET", commands: "a"}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 400
		assert_equal(2208, resp["errors"][0][0])
		assert_equal(2209, resp["errors"][1][0])
	end

	test "Can't create api endpoint with too long properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "a" * 220, method: "POST", commands: "a" * 65100}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2308, resp["errors"][0][0])
		assert_equal(2309, resp["errors"][1][0])
	end

	test "Can't create api endpoint with invalid method" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "test", method: "bla", commands: "(log 'Hello World')"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2406, resp["errors"][0][0])
	end

	test "Can create api endpoint" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		path = "test"
		method = "GET"
		commands = "(log 'Hello World')"

		post "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: path, method: method, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 201
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(path, resp["path"])
		assert_equal(method, resp["method"])
		assert_equal(commands, resp["commands"])
	end

	# Tests for create_api_error endpoint
	test "Missing fields in create_api_error" do
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't create api error without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create api error for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		code = 1111
		message = "Test message"

		post "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: code, message: message}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api error without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error", headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2135, resp["errors"][0][0])
		assert_equal(2136, resp["errors"][1][0])
	end

	test "Can't create api error with too short message" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 1111, message: "a"}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 400
		assert_equal(2210, resp["errors"][0][0])
	end

	test "Can't create api error with too long message" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 1111, message: "a" * 120}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2310, resp["errors"][0][0])
	end

	test "Can't create api error with invalid code" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 12.4, message: "Test error"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2407, resp["errors"][0][0])
	end
	
	test "Can create api error" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		code = 1234
		message = "Test error"

		post "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: code, message: message}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 201
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(code, resp["code"])
		assert_equal(message, resp["message"])
	end

	# Tests for create_api_function
	test "Missing fields in create_api_function" do
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/function"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't create api function without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/function", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create api function for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		name = "testfunction"
		commands = "(log test)"

		post "/v1/api/#{api.id}/function", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: name, commands: commands}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api function without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/function", headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2111, resp["errors"][0][0])
		assert_equal(2134, resp["errors"][1][0])
	end

	test "Can't create api function with too short properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: "a", commands: "a"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
		assert_equal(2209, resp["errors"][1][0])
	end

	test "Can't create api function with too long properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		post "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: "a" * 120, params: "a" * 220, commands: "a" * 65100}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
		assert_equal(2311, resp["errors"][1][0])
		assert_equal(2309, resp["errors"][2][0])
	end

	test "Can create api function" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		name = "testfunction"
		params = "test,bla"
		commands = "(log test)"

		post "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: name, params: params, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 201
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(name, resp["name"])
		assert_equal(params, resp["params"])
		assert_equal(commands, resp["commands"])
	end

	test "Can create api function without params" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		name = "testfunction"
		commands = "(log test)"

		post "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: name, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 201
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(name, resp["name"])
		assert_nil(resp["params"])
		assert_equal(commands, resp["commands"])
	end
end