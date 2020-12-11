require 'test_helper'

class ApisMethodsTest < ActionDispatch::IntegrationTest
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

	# Tests for set_api_endpoint
	test "Missing fields in set_api_endpoint" do
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't set api endpoint without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set api endpoint for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		path = "test"
		method = "GET"
		commands = "(log test)"

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: path, method: method, commands: commands}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't set api endpoint without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint",
			headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2132, resp["errors"][0][0])
		assert_equal(2133, resp["errors"][1][0])
		assert_equal(2134, resp["errors"][2][0])
	end

	test "Can't set api endpoint with too short properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "a", method: "GET", commands: "a"}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 400
		assert_equal(2208, resp["errors"][0][0])
		assert_equal(2209, resp["errors"][1][0])
	end

	test "Can't set api endpoint with too long properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "a" * 220, method: "POST", commands: "a" * 65100}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2308, resp["errors"][0][0])
		assert_equal(2309, resp["errors"][1][0])
	end

	test "Can't set api endpoint with invalid method" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: "test", method: "bla", commands: "(log 'Hello World')"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2406, resp["errors"][0][0])
	end

	test "Can create api endpoint with set_api_endpoint" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		path = "test"
		method = "GET"
		commands = "(log 'Hello World')"

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: path, method: method, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(path, resp["path"])
		assert_equal(method, resp["method"])
		assert_equal(commands, resp["commands"])
	end

	test "Can update api endpoint with set_api_endpoint" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		endpoint = api_endpoints(:TestAppApiCreateTest)
		commands = "(log 'Test')"

		put "/v1/api/#{api.id}/endpoint", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {path: endpoint.path, method: endpoint.method, commands: commands}.to_json
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(endpoint.id, resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(endpoint.path, resp["path"])
		assert_equal(endpoint.method, resp["method"])
		assert_equal(commands, resp["commands"])
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

	# Tests for set_api_function
	test "Missing fields in set_api_function" do
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/function"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't set api function without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/function", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set api function for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		name = "testfunction"
		commands = "(log test)"

		put "/v1/api/#{api.id}/function", 
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: name, commands: commands}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't set api function without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/function", headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2111, resp["errors"][0][0])
		assert_equal(2134, resp["errors"][1][0])
	end

	test "Can't set api function with too short properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: "a", commands: "a"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
		assert_equal(2209, resp["errors"][1][0])
	end

	test "Can't set api function with too long properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: "a" * 120, params: "a" * 220, commands: "a" * 65100}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
		assert_equal(2311, resp["errors"][1][0])
		assert_equal(2309, resp["errors"][2][0])
	end

	test "Can create api function with set_api_function" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		name = "test"
		params = "test,bla"
		commands = "(log test)"

		put "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: name, params: params, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(name, resp["name"])
		assert_equal(params, resp["params"])
		assert_equal(commands, resp["commands"])
	end

	test "Can update api function with set_api_function" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		function = api_functions(:TestAppApiTestFunction)
		commands = "(log test)"

		put "/v1/api/#{api.id}/function",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {name: function.name, params: function.params, commands: commands}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_equal(function.id, resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(function.name, resp["name"])
		assert_equal(function.params, resp["params"])
		assert_equal(commands, resp["commands"])
	end

	# Tests for create_api_error
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

	# Tests for set_api_error
	test "Missing fields in set_api_error" do
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't set api error without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set api error for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		code = 1111
		message = "Test message"

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: code, message: message}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't set api error without required properties" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error", headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2135, resp["errors"][0][0])
		assert_equal(2136, resp["errors"][1][0])
	end

	test "Can't set api error with too short message" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 1111, message: "a"}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 400
		assert_equal(2210, resp["errors"][0][0])
	end

	test "Can't set api error with too long message" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 1111, message: "a" * 120}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2310, resp["errors"][0][0])
	end

	test "Can't set api error with invalid code" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: 12.4, message: "Test error"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2407, resp["errors"][0][0])
	end

	test "Can create api error with set_api_error" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		code = 1234
		message = "Test error"

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: code, message: message}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_not_nil(resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(code, resp["code"])
		assert_equal(message, resp["message"])
	end

	test "Can update api error with set_api_error" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		error = api_errors(:TestAppApiTestError)
		message = "Hello World"

		put "/v1/api/#{api.id}/error",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {code: error.code, message: message}.to_json
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_equal(error.id, resp["id"])
		assert_equal(api.id, resp["api_id"])
		assert_equal(error.code, resp["code"])
		assert_equal(message, resp["message"])
	end

	# Tests for set_api_errors
	test "Missing fields in set_api_errors" do
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/errors"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't set api errors without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/errors", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set api errors for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)
		errors = [{
			code: 1101,
			message: "Resource does not exist: Bla"
		}]

		put "/v1/api/#{api.id}/errors",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {errors: errors}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't set api errors without errors property" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/errors", headers: {Authorization: auth, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2137, resp["errors"][0][0])
	end

	test "Can set api errors" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		test_api_error = api_errors(:TestAppApiTestError)
		test_api_error_new_message = "Hello World"
		api_error_count = api.api_errors.count

		valid_code = 2100
		valid_message = "Resource does not exist: Bla"

		errors = [
			{
				code: -12,
				message: "Blabla"
			},
			{
				code: 2000.20,
				message: "Test test test"
			},
			{
				code: 1200,
				message: "a"
			},
			{
				code: 1234,
				message: "A" * 220
			},
			{
				code: valid_code,
				message: valid_message
			},
			{
				code: test_api_error.code,
				message: test_api_error_new_message
			}
		]

		put "/v1/api/#{api.id}/errors",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {errors: errors}.to_json
		resp = JSON.parse(response.body)

		assert_response 200

		# The api should have one more api error
		api = Api.find_by_id(api.id)
		assert_equal(api_error_count + 1, api.api_errors.count)

		# The valid error should be created
		error = ApiError.find_by(api: api, code: valid_code)
		assert_not_nil(error)
		assert_equal(valid_code, error.code)
		assert_equal(valid_message, error.message)

		# The test api error should be updated
		test_api_error = ApiError.find_by_id(test_api_error.id)
		assert_equal(test_api_error_new_message, test_api_error.message)
	end

	# Tests for set_api_env_vars
	test "Missing fields in set_api_env_vars" do
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/env_vars"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't set api env vars without content type json" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/env_vars", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't set api env vars for api of app of another dev" do
		auth = generate_auth_token(devs(:sherlock))
		api = apis(:TestAppApi)

		put "/v1/api/#{api.id}/env_vars",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: {bla: "test"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can set api env vars" do
		auth = generate_auth_token(devs(:matt))
		api = apis(:TestAppApi)
		test_var = api_env_vars(:TestAppApiTableIdEnvVar)

		string_var_name = "hello"
		string_var_value = "Hello World"
		float_var_name = "float"
		float_var_value = 12.34
		bool_var_name = "boolean"
		bool_var_value = true
		test_var_new_value = 24

		env = Hash.new
		env[string_var_name] = string_var_value
		env[float_var_name] = float_var_value
		env[bool_var_name] = bool_var_value
		env[test_var.name] = test_var_new_value

		put "/v1/api/#{api.id}/env_vars",
			headers: {Authorization: auth, 'Content-Type': 'application/json'},
			params: env.to_json
		resp = JSON.parse(response.body)

		assert_response 200
		
		string_var = ApiEnvVar.find_by(api: api, name: string_var_name)
		assert_not_nil(string_var)
		assert_equal(string_var_value, string_var.value)
		assert_equal(string_var.class_name, "string")

		float_var = ApiEnvVar.find_by(api: api, name: float_var_name)
		assert_not_nil(float_var)
		assert_equal(float_var_value.to_s, float_var.value)
		assert_equal(float_var.class_name, "float")

		bool_var = ApiEnvVar.find_by(api: api, name: bool_var_name)
		assert_not_nil(bool_var)
		assert_equal(bool_var_value.to_s, bool_var.value)
		assert_equal(bool_var.class_name, "bool")

		test_var = ApiEnvVar.find_by(api: api, name: test_var.name)
		assert_not_nil(test_var)
		assert_equal(test_var_new_value.to_s, test_var.value)
		assert_equal(test_var.class_name, "int")
	end
end