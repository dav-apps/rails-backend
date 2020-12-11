require 'test_helper'

class AppsMethodsTest < ActionDispatch::IntegrationTest
	# Tests for create_app
	test "Missing fields in create_app" do
		post "/v1/apps/app"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create app without content type json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/app", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create app with invalid jwt" do
		jwt = "adpjsgdsdf"

		post "/v1/apps/app", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create app from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/app", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "Test", description: "Hello World"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create app without name and description" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/app", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2111, resp["errors"][0][0])
		assert_equal(2112, resp["errors"][1][0])
	end

	test "Can't create app with too short name and description" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/app", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "a", description: "a"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
		assert_equal(2204, resp["errors"][1][0])
	end

	test "Can't create app with too long name and description" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/app", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "a" * 50, description: "a" * 510}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
		assert_equal(2304, resp["errors"][1][0])
	end

	test "Can't create app with invalid links" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		link_web = "helloworld"
		link_play = "blablabla"
		link_windows = "testtest"

		post "/v1/apps/app", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "Test", description: "Hello World", link_web: link_web, link_play: link_play, link_windows: link_windows}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2402, resp["errors"][0][0])
		assert_equal(2403, resp["errors"][1][0])
		assert_equal(2404, resp["errors"][2][0])
	end

	test "Can create app" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		name = "RailsTest"
		description = "This is a test app for tests in Rails"

		post "/v1/apps/app",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name, description: description}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_equal(name, resp["name"])
		assert_equal(description, resp["description"])
		assert_nil(resp["link_web"])
		assert_nil(resp["link_play"])
		assert_nil(resp["link_windows"])
	end

	test "Can create app with links" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		name = "RailsTest"
		description = "This is a test app for tests in Rails"
		link_web = "https://testapp.dav-apps.tech"
		link_play = "https://play.google.com"
		link_windows = "https://store.microsoft.com"

		post "/v1/apps/app",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name, description: description, link_web: link_web, link_play: link_play, link_windows: link_windows}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_equal(name, resp["name"])
		assert_equal(description, resp["description"])
		assert_equal(link_web, resp["link_web"])
		assert_equal(link_play, resp["link_play"])
		assert_equal(link_windows, resp["link_windows"])
	end
   # End create_app tests
   
   # Tests for get_app
   test "Missing fields in get_app" do
      get "/v1/apps/app/#{apps(:Cards).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(resp["errors"].length, 1)
   end
   
   test "App does not exist in get_app" do
      cards_id = apps(:Cards).id
      apps(:Cards).destroy!
      
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{cards_id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_equal(2803, resp["errors"][0][0])
   end
   
   test "get_app can't be called from outside the website" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:dav)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "get_app can be called from the appropriate dev" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get the tables of the app" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(tables(:note).id, resp["tables"][0]["id"])
   end
   
   test "Can't get an app of the first dev as another dev" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End get_app tests

   # get_active_app_users tests
   test "Missing fields in get_active_app_users" do
      get "/v1/apps/app/1/active_users"
      resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end
	
	test "Can't get active app users from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/apps/app/#{apps(:TestApp).id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get active app users of the app of another dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/apps/app/#{apps(:Cards).id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get active app users" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		# Create active app users
		first_active_user = ActiveAppUser.create(
			app: app,
			time: (Time.now - 1.days).beginning_of_day,
			count_daily: 1, 
			count_monthly: 5,
			count_yearly: 17
		)
		second_active_user = ActiveAppUser.create(
			app: app,
			time: (Time.now - 3.days).beginning_of_day,
			count_daily: 6, 
			count_monthly: 9,
			count_yearly: 20
		)

		get "/v1/apps/app/#{app.id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(2, resp["days"].count)

		assert_equal(first_active_user.time, DateTime.parse(resp["days"][0]["time"]))
		assert_equal(first_active_user.count_daily, resp["days"][0]["count_daily"])
		assert_equal(first_active_user.count_monthly, resp["days"][0]["count_monthly"])
		assert_equal(first_active_user.count_yearly, resp["days"][0]["count_yearly"])

		assert_equal(second_active_user.time, DateTime.parse(resp["days"][1]["time"]))
		assert_equal(second_active_user.count_daily, resp["days"][1]["count_daily"])
		assert_equal(second_active_user.count_monthly, resp["days"][1]["count_monthly"])
		assert_equal(second_active_user.count_yearly, resp["days"][1]["count_yearly"])
	end

	test "Can get active app users of the specified timeframe" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_active_user = active_app_users(:first_active_testapp_user)
		second_active_user = active_app_users(:second_active_testapp_user)

		get "/v1/apps/app/#{app.id}/active_users?start=#{start_timestamp}&end=#{end_timestamp}", headers: {'Authorization' => jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(2, resp["days"].count)

		assert_equal(second_active_user.time, DateTime.parse(resp["days"][0]["time"]))
		assert_equal(second_active_user.count_daily, resp["days"][0]["count_daily"])
		assert_equal(second_active_user.count_monthly, resp["days"][0]["count_monthly"])
		assert_equal(second_active_user.count_yearly, resp["days"][0]["count_yearly"])

		assert_equal(first_active_user.time, DateTime.parse(resp["days"][1]["time"]))
		assert_equal(first_active_user.count_daily, resp["days"][1]["count_daily"])
		assert_equal(first_active_user.count_monthly, resp["days"][1]["count_monthly"])
		assert_equal(first_active_user.count_yearly, resp["days"][1]["count_yearly"])
	end
   # End get_active_app_users tests

   # Tests for get_all_apps
   test "Missing fields in get_all_apps" do
      get "/v1/apps/apps/all"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(1, resp["errors"].length)
   end

   test "Can get all apps from the website" do
      auth = generate_auth_token(devs(:sherlock))
      
      get "/v1/apps/apps/all", headers: {'Authorization' => auth}
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get all apps from outside the website" do
      auth = generate_auth_token(devs(:matt))
      
      get "/v1/apps/apps/all", headers: {'Authorization' => auth}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End get_all_apps tests
   
   # update_app tests
   test "Missing fields in update_app" do
      put "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(resp["errors"].length, 1)
   end
   
   test "Can't use another content type but json in update_app" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end
   
   test "User does not exist in update_app" do
      matt_id = users(:matt).id
      test_app_id = apps(:TestApp).id
      
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      users(:matt).destroy!
      
		put "/v1/apps/app/#{test_app_id}", 
				params: {name: "TestApp12133"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_equal(2801, resp["errors"][0][0])
   end
   
   test "update_app can't be called from outside the website" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {name: "TestApp121314"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update an app with too long name and description" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {name: "#{'o' * 35}", description: "#{'o' * 510}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(resp["errors"].length, 2)
      assert_equal(resp["errors"][0][0], 2303)
      assert_equal(resp["errors"][1][0], 2304)
   end
   
   test "Can't update an app with too short name and description" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {name: "a", description: "a"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(resp["errors"].length, 2)
      assert_equal(resp["errors"][0][0], 2203)
      assert_equal(resp["errors"][1][0], 2204)
   end
   
   test "Can't update the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(resp["errors"][0][0], 1102)
   end
   
   test "Can't update the app of the first dev as another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can update name and description of an app at once" do
      new_name = "Neuer Name"
      new_desc = "Neue Beschreibung"
      
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {name: new_name, description: new_desc}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(new_name, resp["name"])
      assert_equal(new_desc, resp["description"])
   end

   test "Can update links of an app" do
      link_play = "https://dav-apps.tech"
      link_windows = "http://microsoft.com/blabla"

      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {link_play: link_play, link_windows: link_windows}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(link_play, resp["link_play"])
      assert_equal(link_windows, resp["link_windows"])
   end

   test "Can update app with blank links" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {link_play: ""}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal("", resp["link_play"])
   end

   test "Can't update app with invalid links" do
      link_play = "bla  blam´a dadasd"
      link_windows = "hellowor-ld124"

      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		put "/v1/apps/app/#{apps(:TestApp).id}", 
				params: {link_play: link_play, link_windows: link_windows}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse(response.body)

      assert_response 400
      assert_equal(2403, resp["errors"][0][0])
      assert_equal(2404, resp["errors"][1][0])
	end
	
	test "Can update published value of app" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		new_published = true
		app_id = apps(:TestApp).id
		
		put "/v1/apps/app/#{app_id}",
				params: {published: new_published}.to_json,
				headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 200
		
		app = App.find_by_id(app_id)
		assert_equal(new_published, app.published)
	end
   # End update_app tests
   
   # delete_app tests
   test "Missing fields in delete_app" do
      delete "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end
   
   test "delete_app can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't delete the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(resp["errors"][0][0], 1102)
   end
   # End delete_app tests
	
	# create_exception tests
	test "Can't create exception without content type json" do
		post "/v1/apps/app/1/exception", headers: {'Content-Type': 'text/plain'}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create exception for app that does not exist" do
		post "/v1/apps/app/-234/exception", headers: {'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can't create exception for the app of another dev" do
		app = apps(:TestApp)
		sherlock = devs(:sherlock)

		post "/v1/apps/app/#{app.id}/exception",
			headers: {'Content-Type': 'application/json'},
			params: {
				api_key: sherlock.api_key,
				name: "asd",
				message: "asdasd",
				stack_trace: "asdasdasdads",
				app_version: "1.0",
				os_version: "10.0.19235",
				device_family: "Windows.Desktop",
				locale: "de-DE"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create exception without required properties" do
		app = apps(:Cards)
		sherlock = devs(:sherlock)

		post "/v1/apps/app/#{app.id}/exception",
			headers: {'Content-Type': 'application/json'},
			params: {}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2118, resp["errors"][0][0])
		assert_equal(2111, resp["errors"][1][0])
		assert_equal(2136, resp["errors"][2][0])
		assert_equal(2145, resp["errors"][3][0])
		assert_equal(2146, resp["errors"][4][0])
		assert_equal(2131, resp["errors"][5][0])
		assert_equal(2147, resp["errors"][6][0])
		assert_equal(2148, resp["errors"][7][0])
	end

	test "Can't create exception with too short properties" do
		app = apps(:Cards)
		sherlock = devs(:sherlock)

		post "/v1/apps/app/#{app.id}/exception",
			headers: {'Content-Type': 'application/json'},
			params: {
				api_key: sherlock.api_key,
				name: "a",
				message: "a",
				stack_trace: "a",
				app_version: "a",
				os_version: "a",
				device_family: "a",
				locale: "a"
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
		assert_equal(2210, resp["errors"][1][0])
		assert_equal(2215, resp["errors"][2][0])
		assert_equal(2216, resp["errors"][3][0])
		assert_equal(2217, resp["errors"][4][0])
		assert_equal(2218, resp["errors"][5][0])
		assert_equal(2219, resp["errors"][6][0])
	end

	test "Can't create exception with too long properties" do
		app = apps(:Cards)
		sherlock = devs(:sherlock)

		post "/v1/apps/app/#{app.id}/exception",
			headers: {'Content-Type': 'application/json'},
			params: {
				api_key: sherlock.api_key,
				name: "a" * 300,
				message: "a" * 600,
				stack_trace: "a" * 10100,
				app_version: "a" * 200,
				os_version: "a" * 300,
				device_family: "a" * 300,
				locale: "a" * 100
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
		assert_equal(2310, resp["errors"][1][0])
		assert_equal(2316, resp["errors"][2][0])
		assert_equal(2317, resp["errors"][3][0])
		assert_equal(2318, resp["errors"][4][0])
		assert_equal(2319, resp["errors"][5][0])
		assert_equal(2320, resp["errors"][6][0])
	end

	test "Can create exception" do
		app = apps(:Cards)
		sherlock = devs(:sherlock)

		name = "System.NotImplementedException"
		message = "The requested method is not implemented!"
		stack_trace = "Lorem ipsum dolor sit amet"
		app_version = "1.7.14"
		os_version = "10.0.19041.388"
		device_family = "Windows.Desktop"
		locale = "de-DE"

		post "/v1/apps/app/#{app.id}/exception",
			headers: {'Content-Type': 'application/json'},
			params: {
				api_key: sherlock.api_key,
				name: name,
				message: message,
				stack_trace: stack_trace,
				app_version: app_version,
				os_version: os_version,
				device_family: device_family,
				locale: locale
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 201

		assert_equal(name, resp["name"])
		assert_equal(message, resp["message"])
		assert_equal(stack_trace, resp["stack_trace"])
		assert_equal(app_version, resp["app_version"])
		assert_equal(os_version, resp["os_version"])
		assert_equal(device_family, resp["device_family"])
		assert_equal(locale, resp["locale"])

		exception = ExceptionEvent.find_by_id(resp["id"])
		assert_not_nil(exception)
		assert_equal(app, exception.app)
		assert_equal(name, exception.name)
		assert_equal(message, exception.message)
		assert_equal(stack_trace, exception.stack_trace)
		assert_equal(app_version, exception.app_version)
		assert_equal(os_version, exception.os_version)
		assert_equal(device_family, exception.device_family)
		assert_equal(locale, exception.locale)
	end
	# End create_exception tests

   # create_object tests
   test "Missing fields in create_object" do
      post "/v1/apps/object"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(resp["errors"].length, 3)
   end
   
   test "Can't create object when using another Content-Type than application/json" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
	end
   
   test "Table does not exist and gets created when the user is the dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=NewTable&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert(Table.find_by(name: "NewTable"))
   end
   
   test "Can't create a new table in create_object with too short table_name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=N&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2205, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with too long table_name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{"n"*220}&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2305, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with an invalid table_name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=New Table name&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2501, resp["errors"][0][0])
   end

   test "Can't create an object with table id if the table does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?table_id=133&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 404
      assert_equal(2804, resp["errors"][0][0])
   end
   
   test "Can't create an object for the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't create an empty object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2116, resp["errors"][0][0])
   end
   
   test "Can't create an object with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				params: {"": "a"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2206, resp["errors"][0][0])
   end
   
   test "Can't create an object with too long name and value" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				params: {"#{'n' * 220}": "#{'n' * 65500}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2306, resp["errors"][0][0])
      assert_equal(2307, resp["errors"][1][0])
   end
   
   test "Can't create object with visibility > 2" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=5&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(0, resp["visibility"])
   end
   
   test "Can't create object with visibility < 0" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=-4&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(0, resp["visibility"])
   end
   
   test "Can't create object with visibility that is not an integer" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=hello&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(0, resp["visibility"])
   end
   
   test "Can create object with another visibility" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(2, resp["visibility"])
   end

   test "Can't create object and upload file without ext parameter" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end

   test "Can create object and upload text file" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		content_type = 'text/plain'
		ext = "txt"

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=#{ext}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
      resp = JSON.parse response.body

      assert_response 201
      assert_not_nil(resp["id"])
		
		# Check if the properties were created
		assert_equal(ext, resp["properties"]["ext"])
		assert_equal(content_type, resp["properties"]["type"])
		assert_not_nil(resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
   end

   test "Can create object and upload empty file" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		content_type = 'text/plain'
		ext = "txt"

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=#{ext}", 
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
      resp = JSON.parse response.body

		assert_response 201
		
		# Check if the properties were created
		assert_equal(ext, resp["properties"]["ext"])
		assert_equal(content_type, resp["properties"]["type"])
		assert_equal("0", resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
   end

   test "Can't create object and upload file with empty Content-Type header" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end

   test "Can create object with uuid and get correct etag" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      uuid = SecureRandom.uuid

		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&uuid=#{uuid}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
		object = TableObject.find_by(uuid: uuid)
		assert_not_nil(object)
		assert_equal(uuid, resp["uuid"])
		assert_equal(generate_table_object_etag(object), resp["etag"])
   end

   test "Can't create object with uuid that is already in use" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&uuid=#{table_objects(:third).uuid}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2704, resp["errors"][0][0])
   end

   test "Can create object with binary file and get correct etag" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&ext=png", 
				params: File.open('test/fixtures/files/test.png', 'rb').read,
				headers: {'Authorization' => jwt, "Content-Type": "image/png"}
      resp = JSON.parse response.body
      
		assert_response 201

		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)

      assert_equal(tables(:card).id, resp["table_id"])
		assert_not_nil(resp["properties"]["etag"])
		assert_equal(generate_table_object_etag(object), resp["etag"])

      # Delete the object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
   end

   test "Can create object with table_id" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
	end
	
	test "Can create object with table_id and session jwt" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")

		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
	end

   test "Can create object with uuid and table_id" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      uuid = SecureRandom.uuid

		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}&uuid=#{uuid}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(resp["uuid"], uuid)
   end

   test "Can't create an object for the app of another dev with table_id" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can create object with table_id and another visibility and upload text file" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		visibility = 1
		ext = "txt"
		content_type = 'text/plain'

		post "/v1/apps/object?table_id=#{tables(:note).id}&visibility=#{visibility}&app_id=#{apps(:TestApp).id}&ext=#{ext}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
      resp = JSON.parse response.body

      assert_response 201
      assert_not_nil(resp["id"])
		assert_equal(resp["visibility"], visibility)
		
		# Check if the properties were created
		assert_equal(ext, resp["properties"]["ext"])
		assert_equal(content_type, resp["properties"]["type"])
		assert_not_nil(resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      
      assert_response 200
	end

	test "Can create object with different data types" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		first_property_name = "page"
		first_property_value = 123
		second_property_name = "bool"
		second_property_value = true
		third_property_name = "zoom"
		third_property_value = 12.34

		post "/v1/apps/object?table_id=#{tables(:note).id}&app_id=#{apps(:TestApp).id}",
				headers: {Authorization: jwt, 'Content-Type': 'application/json'},
				params: {
					"#{first_property_name}": first_property_value,
					"#{second_property_name}": second_property_value,
					"#{third_property_name}": third_property_value
				}.to_json
		resp = JSON.parse response.body
		
		assert_response 201
		
		assert_equal(first_property_value, resp["properties"][first_property_name])
		assert_equal(second_property_value, resp["properties"][second_property_name])
		assert_equal(third_property_value, resp["properties"][third_property_name])
		
		obj = TableObject.find_by_id(resp["id"])

		assert_not_nil(obj)
		assert_equal(first_property_value.to_s, obj.properties[0].value)
		assert_equal(second_property_value.to_s, obj.properties[1].value)
		assert_equal(third_property_value.to_s, obj.properties[2].value)
	end
	
	test "create_object should not create a property when the property has no value" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		first_property_name = "test1"
		first_property_value = ""
		second_property_name = "test2"
		second_property_value = "blabla"
		properties = {"#{first_property_name}": first_property_value, "#{second_property_name}": second_property_value}

		post "/v1/apps/object?table_id=#{tables(:note).id}&app_id=#{apps(:TestApp).id}", 
				params: properties.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body
		
		assert_response 201
		obj = TableObject.find_by_id(resp["id"])
		assert_not_nil(obj)
		assert_equal(1, obj.properties.count)
		assert_equal(second_property_name, obj.properties.first.name)
		assert_equal(second_property_value, obj.properties.first.value)
	end

	test "create_object should update the last_active fields of the user and the users_app" do
		matt = users(:matt)
      matt_cards = users_apps(:mattCards)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at
		
		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", 
				params: '{"test": "test"}', 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

		assert_response 201
		matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

		assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end

	test "Can't create object for table that does not belong to the app" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/object?table_id=#{tables(:card).id}&app_id=#{apps(:TestApp).id}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body
		
		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end
   # End create_object tests
   
   # get_object tests
   test "Can't get a table object that does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/-20", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_equal(2805, resp["errors"][0][0])
   end
   
   test "Can't get the objects of the tables of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:sixth).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can get own object and all properties" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:first).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
		assert_response 200
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(table_objects(:first).id, resp["id"])
		assert_equal(generate_table_object_etag(object), resp["etag"])
      assert_not_nil(resp["properties"]["page1"])
      assert_not_nil(resp["properties"]["page2"])
	end

	test "Can get own object with different property data types" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/apps/object/#{table_objects(:ninth).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		
		assert_equal(Integer(properties(:first9).value), resp["properties"][properties(:first9).name])
		assert_equal(properties(:second9).value == "true", resp["properties"][properties(:second9).name])
		assert_equal(Float(properties(:third9).value), resp["properties"][properties(:third9).name])
	end

	test "Can get object with access" do
		cato = users(:cato)
		jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]

		get "/v1/apps/object/#{table_objects(:third).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(generate_table_object_etag(object), resp["etag"])
	end
	
	test "Can get object with session jwt" do
		matt = users(:matt)
		obj = table_objects(:first)
		jwt = generate_session_jwt(matt, devs(:sherlock), obj.table.app_id, "schachmatt")
		
      get "/v1/apps/object/#{obj.id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
		assert_response 200
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(table_objects(:first).id, resp["id"])
		assert_equal(generate_table_object_etag(object), resp["etag"])
      assert_not_nil(resp["properties"]["page1"])
      assert_not_nil(resp["properties"]["page2"])
	end

	test "Can get object with access with session jwt" do
		cato = users(:cato)
		jwt = generate_session_jwt(cato, devs(:sherlock), apps(:Cards).id, "123456")

		get "/v1/apps/object/#{table_objects(:third).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(generate_table_object_etag(object), resp["etag"])
	end
   
   test "Can't access an object when the user does not own the object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:second).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't get object without access token and JWT" do
      get "/v1/apps/object/#{table_objects(:second).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2102, resp["errors"][0][0])
      assert_equal(2117, resp["errors"][1][0])
   end
   
   test "Can get object with access token without logging in" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object_id = table_objects(:third).id
      
      post "/v1/apps/object/#{object_id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 201
      
      token = resp["token"]
      
      get "/v1/apps/object/#{object_id}?access_token=#{token}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get protected object as another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:first).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get protected object with uploaded file as another user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=1&app_id=#{apps(:TestApp).id}&ext=txt", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => matts_jwt, 'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => sherlocks_jwt}
      resp2 = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp2["errors"][0][0])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => matts_jwt}
      
      assert_response 200
   end
   
   test "Can get public object as logged in user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:eight).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get public object without being logged in" do
      get "/v1/apps/object/#{table_objects(:eight).id}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can get object with uploaded file" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		ext = "txt"
		content_type = 'text/plain'

		# Create the object with file
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=#{ext}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
      resp = JSON.parse response.body

		assert_response 201
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(generate_table_object_etag(object), resp["etag"])
      assert_not_nil(resp["properties"]["etag"])

      get "/v1/apps/object/#{resp["id"]}?file=true", headers: {'Authorization' => jwt}
      resp2 = response.body

		assert_response 200
		assert_equal(content_type, response.headers["Content-Type"])
		assert(!resp2.include?("id"))
		
		# Check if the properties were created
		assert_equal(ext, resp["properties"]["ext"])
		assert_equal(content_type, resp["properties"]["type"])
		assert_not_nil(resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
   end

   test "Can get object with uuid" do
      get "/v1/apps/object/#{table_objects(:eight).uuid}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(table_objects(:eight).uuid, resp["uuid"])
   end

   test "Can get object with uploaded file with uuid" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		uuid = SecureRandom.uuid
		ext = "txt"
		content_type = 'text/plain'

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=#{ext}&uuid=#{uuid}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
      resp = JSON.parse response.body

		assert_response 201
		
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(generate_table_object_etag(object), resp["etag"])

      get "/v1/apps/object/#{uuid}?file=true", headers: {'Authorization' => jwt}
      resp2 = response.body

		assert_response 200
		assert_equal(content_type, response.headers["Content-Type"])
		assert(!resp2.include?("id"))
		
		# Check if the properties were created
		assert_equal(ext, resp["properties"]["ext"])
		assert_equal(content_type, resp["properties"]["type"])
		assert_not_nil(resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{uuid}", headers: {'Authorization' => jwt}
      
      assert_response 200
	end
	
	test "get_object should update the last_active fields of the user and the users_app" do
      matt = users(:matt)
      matt_cards = users_apps(:mattCards)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at
		
		get "/v1/apps/object/#{table_objects(:third).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		# Check the last_active field of the user
		assert_response 200
		matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

		assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end
   # End get_object tests

   # get_object_with_auth tests
   test "Missing fields in get_object_with_auth" do
      obj = table_objects(:second)

      get "/v1/apps/object/#{obj.id}/auth"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2101, resp["errors"][0][0])
	end
	
	test "Can't get a table object with auth that does not exist" do
		auth = generate_auth_token(devs(:matt))

		get "/v1/apps/object/-20/auth", headers: {'Authorization' => auth}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2805, resp["errors"][0][0])
	end

	test "Can't get the table object of the app of another dev with auth" do
		auth = generate_auth_token(devs(:matt))
		obj = table_objects(:second)

		get "/v1/apps/object/#{obj.id}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get the table object of the app of another dev with auth and uuid" do
		auth = generate_auth_token(devs(:matt))
		obj = table_objects(:second)

		get "/v1/apps/object/#{obj.uuid}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get file of table object with auth" do
		# Create the object with file
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		ext = 'txt'
		content_type = 'text/plain'
		file_content = "Hello World! This is a text file."

		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}&ext=#{ext}",
				params: file_content,
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
		resp = JSON.parse response.body

		assert_response 201
		obj = TableObject.find_by_id(resp["id"])
		assert_not_nil(obj)

		# Try to get the file of the object with auth
		auth = generate_auth_token(devs(:matt))

		get "/v1/apps/object/#{resp["id"]}/auth?file=true", 
				headers: {'Authorization' => auth}
		resp2 = response.body

		assert_response 200
		assert_equal(content_type, response.headers["Content-Type"])
		assert_equal(file_content, resp2)

		# Delete the object
		delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
		assert_response 200
	end

	test "Can get file of table object with auth and uuid" do
		# Create the object with file
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		ext = 'txt'
		content_type = 'text/plain'
		file_content = "Hello World! This is a text file."

		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}&ext=#{ext}",
				params: file_content,
				headers: {'Authorization' => jwt, 'Content-Type' => content_type}
		resp = JSON.parse(response.body)

		assert_response 201
		obj = TableObject.find_by_id(resp["id"])
		assert_not_nil(obj)

		# Try to get the file of the object with auth and uuid
		auth = generate_auth_token(devs(:matt))

		get "/v1/apps/object/#{resp["uuid"]}/auth?file=true", 
				headers: {'Authorization' => auth}
		resp2 = response.body

		assert_response 200
		assert_equal(content_type, response.headers["Content-Type"])
		assert_equal(file_content, resp2)

		# Delete the object
		delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
		assert_response 200
	end

	test "Can get table object with auth" do
		auth = generate_auth_token(devs(:sherlock))
		obj = table_objects(:third)

		get "/v1/apps/object/#{obj.id}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(obj.id, resp["id"])
		assert_equal(obj.uuid, resp["uuid"])
		
		obj.properties.each do |prop|
			assert_equal(prop.value, resp["properties"][prop.name])
		end
	end

	test "Can get table object with auth with different property data types" do
		auth = generate_auth_token(devs(:sherlock))
		obj = table_objects(:ninth)

		get "/v1/apps/object/#{obj.id}/auth", headers: {Authorization: auth}
		resp = JSON.parse(response.body)

		assert_response 200

		assert_equal(Integer(properties(:first9).value), resp["properties"][properties(:first9).name])
		assert_equal(properties(:second9).value == "true", resp["properties"][properties(:second9).name])
		assert_equal(Float(properties(:third9).value), resp["properties"][properties(:third9).name])
	end

	test "Can get table object with auth and uuid" do
		auth = generate_auth_token(devs(:sherlock))
		obj = table_objects(:third)

		get "/v1/apps/object/#{obj.uuid}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(obj.id, resp["id"])
		assert_equal(obj.uuid, resp["uuid"])
		
		obj.properties.each do |prop|
			assert_equal(prop.value, resp["properties"][prop.name])
		end
	end
   # End get_object_with_auth tests
   
   # update_object tests
   test "Can't update an object when the user does not own the object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:dav)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:second).id}", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update an object with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}", 
				params: {"": "a"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2206, resp["errors"][0][0])
   end
   
   test "Can't update an object with too long name and value" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}", 
				params: {"#{'n' * 220}": "#{'n' * 65500}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2306, resp["errors"][0][0])
      assert_equal(2307, resp["errors"][1][0])
   end
   
   test "update_object returns all properties of the object" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		table_object = table_objects(:first)
		first_property_name = properties(:first1).name
		first_property_value = "updated property value"
		second_property_name = properties(:second1).name
		second_property_value = properties(:second1).value
      
		put "/v1/apps/object/#{table_object.id}", 
				params: {"#{first_property_name}": first_property_value}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
		assert_equal(first_property_value, resp["properties"][first_property_name])
		assert_equal(second_property_value, resp["properties"][second_property_name])
	end
	
	test "Can update object with different data types" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		first_property_name = properties(:first9).name
		first_property_value = 321
		second_property_name = properties(:second9).name
		second_property_value = properties(:second9).value == "true"
		third_property_name = properties(:third9).name
		third_property_value = Float(properties(:third9).value)
		fourth_property_name = "test1"
		fourth_property_value = 456
		fifth_property_name = "test2"
		fifth_property_value = false
		sixth_property_name = "test3"
		sixth_property_value = 73.145

		put "/v1/apps/object/#{table_objects(:ninth).id}",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {
				"#{first_property_name}": first_property_value,
				"#{fourth_property_name}": fourth_property_value,
				"#{fifth_property_name}": fifth_property_value,
				"#{sixth_property_name}": sixth_property_value
			}.to_json
		resp = JSON.parse(response.body)

		assert_response 200

		assert_equal(first_property_value, resp["properties"][first_property_name])
		assert_equal(second_property_value, resp["properties"][second_property_name])
		assert_equal(third_property_value, resp["properties"][third_property_name])
		assert_equal(fourth_property_value, resp["properties"][fourth_property_name])
		assert_equal(fifth_property_value, resp["properties"][fifth_property_name])
		assert_equal(sixth_property_value, resp["properties"][sixth_property_name])

		obj = TableObject.find_by_id(resp["id"])

		assert_not_nil(obj)
		assert_equal(first_property_value.to_s, obj.properties.find{ |prop| prop.name == first_property_name }.value)
		assert_equal(second_property_value.to_s, obj.properties.find{ |prop| prop.name == second_property_name }.value)
		assert_equal(third_property_value.to_s, obj.properties.find{ |prop| prop.name == third_property_name }.value)
		assert_equal(fourth_property_value.to_s, obj.properties.find{ |prop| prop.name == fourth_property_name }.value)
		assert_equal(fifth_property_value.to_s, obj.properties.find{ |prop| prop.name == fifth_property_name }.value)
		assert_equal(sixth_property_value.to_s, obj.properties.find{ |prop| prop.name == sixth_property_name }.value)

		# Check the property types
		first_type = obj.table.property_types.find{ |type| type.name == first_property_name }
		assert_equal(first_type.data_type, 2)

		second_type = obj.table.property_types.find{ |type| type.name == second_property_name }
		assert_equal(second_type.data_type, 1)

		third_type = obj.table.property_types.find{ |type| type.name == third_property_name }
		assert_equal(third_type.data_type, 3)

		fourth_type = obj.table.property_types.find{ |type| type.name == fourth_property_name }
		assert_equal(fourth_type.data_type, 2)

		fifth_type = obj.table.property_types.find{ |type| type.name == fifth_property_name }
		assert_equal(fifth_type.data_type, 1)

		sixth_type = obj.table.property_types.find{ |type| type.name == sixth_property_name }
		assert_equal(sixth_type.data_type, 3)
	end
   
   test "Can update object with new visibility" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}?visibility=2", 
				params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body
      
		assert_response 200
		object = TableObject.find_by_id(resp["id"])
		assert_not_nil(object)
		assert_equal(generate_table_object_etag(object), resp["etag"])
      assert_equal(2, resp["visibility"])
   end
   
   test "Can't update an object with invalid visibility" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}?visibility=hello", 
				params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(0, resp["visibility"])
   end

	test "Can't update object without content type header" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		put "/v1/apps/object/#{table_objects(:third).uuid}", 
				params: {page1: "test", page2: "test2"}.to_json,
				headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

   test "Can update visibility and ext of object with file" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		old_ext = "txt"
		old_content_type = 'text/plain'

      # Create object
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=#{old_ext}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => old_content_type}
      resp = JSON.parse response.body

      assert_response 201
      
      etag = resp["properties"]["etag"]
      assert_not_nil(etag)

		new_ext = "html"
		new_content_type = 'text/html'
      new_visibility = 2

      # Update object
		put "/v1/apps/object/#{resp["id"]}?visibility=#{new_visibility}&ext=#{new_ext}", 
				params: "<p>Hallo Welt! Dies ist eine HTML-Datei.</p>", 
				headers: {'Authorization' => jwt, 'Content-Type' => new_content_type}
      resp = JSON.parse response.body

		assert_response 200
		assert_equal(new_visibility, resp["visibility"])
		assert_equal(new_ext, resp["properties"]["ext"])
		assert_equal(new_content_type, resp["properties"]["type"])
		assert_not_nil(resp["properties"]["size"])
		assert_not_nil(resp["properties"]["etag"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      
      assert_response 200
   end

   test "Can update object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		new_page1 = "Hallo Welt"
		new_page2 = "Hello World"
      
		put "/v1/apps/object/#{table_objects(:third).uuid}", 
				params: {page1: new_page1, page2: new_page2}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 200
		assert_equal(new_page1, resp["properties"]["page1"])
		assert_equal(new_page2, resp["properties"]["page2"])
	end
	
	test "Can update object with session jwt" do
		matt = users(:matt)
		obj = table_objects(:third)
		jwt = generate_session_jwt(matt, devs(:sherlock), obj.table.app_id, "schachmatt")
		new_page1 = "Hallo Welt"
		new_page2 = "Hello World"
      
		put "/v1/apps/object/#{obj.uuid}", 
				params: {page1: new_page1, page2: new_page2}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 200
		assert_equal(new_page1, resp["properties"]["page1"])
		assert_equal(new_page2, resp["properties"]["page2"])
	end

   test "Can update object and replace uploaded file" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      file1Path = "test/fixtures/files/test.png"
		file2Path = "test/fixtures/files/test2.mp3"
		old_ext = "png"
		old_content_type = 'image/png'

		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&ext=#{old_ext}", 
				params: File.open(file1Path, "rb").read, 
				headers: {'Authorization' => jwt, 'Content-Type' => old_content_type}
      resp = JSON.parse response.body
      
		assert_response 201

		object1 = TableObject.find_by_id(resp["id"])
		assert_not_nil(object1)
		object_etag = resp["etag"]
      etag = resp["properties"]["etag"]
      assert_equal(File.size(file1Path), resp["properties"]["size"].to_i)
		assert_not_nil(etag)
		assert_equal(generate_table_object_etag(object1), object_etag)

		assert_equal(old_ext, resp["properties"]["ext"])
		assert_equal(old_content_type, resp["properties"]["type"])

		new_ext = "mp3"
		new_content_type = 'audio/mpeg'

		put "/v1/apps/object/#{resp["id"]}?ext=#{new_ext}", 
				params: File.open(file2Path, "rb").read, 
				headers: {'Authorization' => jwt, 'Content-Type' => new_content_type}
      resp2 = JSON.parse response.body
      
		assert_response 200

		object2 = TableObject.find_by_id(resp2["id"])
		assert_not_nil(object2)
		object_etag2 = resp2["etag"]
      etag2 = resp2["properties"]["etag"]
      assert_equal(File.size(file2Path), resp2["properties"]["size"].to_i)
      assert_not_nil(etag2)
		assert_not_equal(etag, etag2)
		assert_not_equal(object_etag, object_etag2)
		assert_equal(generate_table_object_etag(object2), object_etag2)

		assert_equal(new_ext, resp2["properties"]["ext"])
		assert_equal(new_content_type, resp2["properties"]["type"])

      delete "/v1/apps/object/#{resp["id"]}", headers: {'Authorization' => jwt}
      assert_response 200
	end
	
	test "update_object does not create a new property if the value is empty" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		table_object = table_objects(:third)
		old_properties_count = table_object.properties.count
		properties = '{"page3": ""}'
		
		put "/v1/apps/object/#{table_object.id}", 
				params: properties, 
				headers: {"Authorization" => jwt, "Content-Type" => "application/json"}
		resp = JSON.parse response.body

		assert_response 200
		obj = TableObject.find_by_id(table_object.id)
		assert_equal(old_properties_count, obj.properties.count)
	end

	test "update_object removes existing property if the value is empty" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		table_object = table_objects(:third)
		old_properties_count = table_object.properties.count
		properties = {page2: ""}

		put "/v1/apps/object/#{table_object.id}", 
				params: properties.to_json, 
				headers: {"Authorization" => jwt, "Content-Type" => "application/json"}
		resp = JSON.parse response.body

		assert_response 200
		obj = TableObject.find_by_id(table_object.id)
		assert_equal(old_properties_count - 1, obj.properties.count)
	end

	test "update_object removes existing property if the value is nil" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		table_object = table_objects(:third)
		old_properties_count = table_object.properties.count
		properties = {page2: nil}

		put "/v1/apps/object/#{table_object.id}", 
				params: properties.to_json, 
				headers: {"Authorization" => jwt, "Content-Type" => "application/json"}
		resp = JSON.parse response.body

		assert_response 200
		obj = TableObject.find_by_id(table_object.id)
		assert_equal(old_properties_count - 1, obj.properties.count)
	end

	test "update_object should update the last_active fields of the user and the users_app" do
      matt = users(:matt)
      matt_cards = users_apps(:mattCards)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		new_page1 = "Hallo Welt"
		new_page2 = "Hello World"
      old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at

		put "/v1/apps/object/#{table_objects(:third).uuid}", 
				params: {page1: new_page1, page2: new_page2}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

		assert_response 200
      matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

      assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end
   # End update_object tests
   
   # delete_object tests
   test "Can't delete an object when the dev does not own the table" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:seventh).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't delete an object of another user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:second).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can delete an object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:first).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
	end
	
	test "Can delete an object with session jwt" do
		matt = users(:matt)
		obj = table_objects(:first)
		jwt = generate_session_jwt(matt, devs(:sherlock), obj.table.app_id, "schachmatt")
      
      delete "/v1/apps/object/#{obj.id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can delete object with uuid" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:first).uuid}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
	end
	
	test "delete_object should update the last_active fields of the user and the users_app" do
      matt = users(:matt)
      matt_cards = users_apps(:mattCards)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at

		delete "/v1/apps/object/#{table_objects(:first).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 200
      matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

      assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end
	# End delete_object tests
	
	# add_object tests
	test "Can't add object without jwt" do
		post "/v1/apps/object/1/access"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't add object of app of another dev" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:matt), apps(:TestApp).id, "schachmatt")
		obj = table_objects(:third)

		post "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can add object" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")
		obj = table_objects(:third)

		post "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201
		
		access = TableObjectUserAccess.find_by_id(resp["id"])
		assert_not_nil(access)
		assert_equal(resp["table_object_id"], access.table_object_id)
		assert_equal(resp["user_id"], access.user_id)
		assert_equal(resp["table_alias"], access.table_alias)

		assert_equal(access.table_object_id, obj.id)
		assert_equal(access.user_id, matt.id)
		assert_equal(access.table_alias, obj.table.id)
	end

	test "Can add object with uuid" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")
		obj = table_objects(:third)

		post "/v1/apps/object/#{obj.uuid}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201
		
		access = TableObjectUserAccess.find_by_id(resp["id"])
		assert_not_nil(access)
		assert_equal(resp["table_object_id"], access.table_object_id)
		assert_equal(resp["user_id"], access.user_id)
		assert_equal(resp["table_alias"], access.table_alias)
		
		assert_equal(access.table_object_id, obj.id)
		assert_equal(access.user_id, matt.id)
		assert_equal(access.table_alias, obj.table.id)
	end

	test "Can add object with table alias" do
		sherlock = users(:sherlock)
		jwt = generate_session_jwt(sherlock, devs(:matt), apps(:TestApp).id, "sherlocked")
		obj = table_objects(:fifth)
		table_alias = tables(:testTable).id

		post "/v1/apps/object/#{obj.id}/access?table_alias=#{table_alias}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201
		
		access = TableObjectUserAccess.find_by_id(resp["id"])
		assert_not_nil(access)
		assert_equal(resp["table_object_id"], access.table_object_id)
		assert_equal(resp["user_id"], access.user_id)
		assert_equal(resp["table_alias"], access.table_alias)
		
		assert_equal(access.table_object_id, obj.id)
		assert_equal(access.user_id, sherlock.id)
		assert_equal(access.table_alias, table_alias)
	end

	test "Can add object with uuid and table alias" do
		sherlock = users(:sherlock)
		jwt = generate_session_jwt(sherlock, devs(:matt), apps(:TestApp).id, "sherlocked")
		obj = table_objects(:fifth)
		table_alias = tables(:testTable).id

		post "/v1/apps/object/#{obj.uuid}/access?table_alias=#{table_alias}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 201
		
		access = TableObjectUserAccess.find_by_id(resp["id"])
		assert_not_nil(access)
		assert_equal(resp["table_object_id"], access.table_object_id)
		assert_equal(resp["user_id"], access.user_id)
		assert_equal(resp["table_alias"], access.table_alias)
		
		assert_equal(access.table_object_id, obj.id)
		assert_equal(access.user_id, sherlock.id)
		assert_equal(access.table_alias, table_alias)
	end
	# End add_object tests

	# remove_object tests
	test "Missing fields in remove_object" do
		delete "/v1/apps/object/1/access"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't remove object that does not exist" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")

		delete "/v1/apps/object/-123/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2805, resp["errors"][0][0])
	end

	test "Can't remove object to which the user has no access to" do
		matt = users(:matt)
		obj = table_objects(:second)
		jwt = generate_session_jwt(matt, devs(:sherlock), obj.table.app_id, "schachmatt")

		delete "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)
	
		assert_response 404
		assert_equal(2819, resp["errors"][0][0])
	end

	test "Can't remove object which belongs to the app of another dev" do
		matt = users(:matt)
		obj = table_objects(:third)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:dav)).body)["jwt"]

		delete "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can remove object" do
		cato = users(:cato)
		obj = table_objects(:third)
		access = table_object_user_accesses(:catoAccessThirdTableObject)
		jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]

		delete "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		
		# Check if the TableObjectUserAccess was deleted
		access = TableObjectUserAccess.find_by_id(access.id)
		assert_nil(access)
	end

	test "Can remove object with session jwt" do
		cato = users(:cato)
		obj = table_objects(:third)
		access = table_object_user_accesses(:catoAccessThirdTableObject)
		jwt = generate_session_jwt(cato, devs(:sherlock), obj.table.app_id, "123456")

		delete "/v1/apps/object/#{obj.id}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		
		# Check if the TableObjectUserAccess was deleted
		access = TableObjectUserAccess.find_by_id(access.id)
		assert_nil(access)
	end

	test "Can remove object with uuid" do
		cato = users(:cato)
		obj = table_objects(:third)
		access = table_object_user_accesses(:catoAccessThirdTableObject)
		jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]

		delete "/v1/apps/object/#{obj.uuid}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		
		# Check if the TableObjectUserAccess was deleted
		access = TableObjectUserAccess.find_by_id(access.id)
		assert_nil(access)
	end

	test "Can remove object with uuid and session jwt" do
		cato = users(:cato)
		obj = table_objects(:third)
		access = table_object_user_accesses(:catoAccessThirdTableObject)
		jwt = generate_session_jwt(cato, devs(:sherlock), obj.table.app_id, "123456")

		delete "/v1/apps/object/#{obj.uuid}/access", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		
		# Check if the TableObjectUserAccess was deleted
		access = TableObjectUserAccess.find_by_id(access.id)
		assert_nil(access)
	end
	# End remove_object tests
   
	# create_table tests
	test "Missing fields in create_table" do
		post "/v1/apps/1/table", headers: {'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create table without content type json" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/#{app.id}/table", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create table for the app of another dev from the website" do
		matt = users(:matt)
		app = apps(:davApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "Blabla"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create table for the app of another dev from outside the website" do
		matt = users(:matt)
		app = apps(:davApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "Blabla"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create table with the name of an existing table" do
		matt = users(:matt)
		app = apps(:TestApp)
		table = tables(:note)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: table.name}.to_json
		resp = JSON.parse(response.body)

		assert_response 409
		assert_equal(2904, resp["errors"][0][0])
	end

	test "Can't create table with too short name" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: 'a'}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
	end

	test "Can't create table with too long name" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: 'a' * 220}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
	end

	test "Can't create table with invalid name" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: 'Hello World'}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2502, resp["errors"][0][0])
	end

	test "Can create table from the website" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		name = "Test"

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_equal(name, resp["name"])
	end

	test "Can create table from outside the website" do
		matt = users(:matt)
		app = apps(:TestApp)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		name = "Test"

		post "/v1/apps/#{app.id}/table",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_equal(name, resp["name"])
	end
   # End create_table tests
   
   # get_table tests
   test "Missing fields in get_table" do
      get "/v1/apps/table"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
      assert_equal(2110, resp["errors"][1][0])
      assert_equal(2113, resp["errors"][2][0])
   end
   
   test "Can't get the table of the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't get the table of the app of another dev from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can get the table and only the entries of the current user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(apps(:Cards).id, resp["app_id"])
      resp["table_objects"].each do |e|
			obj = TableObject.find_by_id(e["id"])
			assert_not_nil(obj)
			assert_equal(generate_table_object_etag(obj), e["etag"])
			assert_equal(users(:matt).id, obj.user.id)
      end
	end

	test "Can get table with table objects of the current user and with access" do
		cato = users(:cato)
		jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]
		expected_table_objects = [table_objects(:second), table_objects(:third), table_objects(:sixth)]

		get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}",
			headers: {Authorization: jwt}
		resp = JSON.parse(response.body)
		
		assert_response 200
		assert_equal(3, resp["table_objects"].size)

		i = 0
		expected_table_objects.each do |obj|
			assert_equal(obj.id, resp["table_objects"][i]["id"])
			assert_equal(obj.table_id, resp["table_objects"][i]["table_id"])
			assert_equal(obj.uuid, resp["table_objects"][i]["uuid"])
			assert_equal(generate_table_object_etag(obj), resp["table_objects"][i]["etag"])
			i += 1
		end
	end
	
	test "Can get the table and only the entries of the current user with session jwt" do
      matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")
      
      get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(apps(:Cards).id, resp["app_id"])
      resp["table_objects"].each do |e|
			obj = TableObject.find_by_id(e["id"])
			assert_not_nil(obj)
			assert_equal(generate_table_object_etag(obj), e["etag"])
			assert_equal(users(:matt).id, obj.user.id)
      end
	end

	test "Can get table with table objects of the current user and with access with session jwt" do
		cato = users(:cato)
		jwt = generate_session_jwt(cato, devs(:sherlock), apps(:Cards).id, "123456")
		expected_table_objects = [table_objects(:second), table_objects(:third), table_objects(:sixth)]

		get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}",
			headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(3, resp["table_objects"].size)

		i = 0
		expected_table_objects.each do |obj|
			assert_equal(obj.id, resp["table_objects"][i]["id"])
			assert_equal(obj.table_id, resp["table_objects"][i]["table_id"])
			assert_equal(obj.uuid, resp["table_objects"][i]["uuid"])
			assert_equal(generate_table_object_etag(obj), resp["table_objects"][i]["etag"])
			i += 1
		end
	end
   
   test "Can get the table of the app of the own dev from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end

	test "Can get a table in pages" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		count = 1
		page = 1
		
		get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&count=#{count}&page=#{page}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_equal(count, resp["table_objects"].count)
		assert_equal(table_objects(:first).uuid, resp["table_objects"][0]["uuid"])
	end

	test "Can get the second page of a table" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		count = 1
		page = 2
		
		get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&count=#{count}&page=#{page}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_equal(count, resp["table_objects"].count)
		assert_equal(table_objects(:third).uuid, resp["table_objects"][0]["uuid"])
	end

	test "get_table should update the last_active fields of the user and the users_app" do
      matt = users(:matt)
      matt_cards = users_apps(:mattCards)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at

		get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
      matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

      assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end
   # End get_table tests

   # get_table_by_id tests
   test "Missing fields in get_table_by_id" do
      get "/v1/apps/table/#{tables(:card).id}"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get the table of the app of another dev by id" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:davTable).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't get the table of the app of another dev by id from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:davTable).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can get the table by id and only the entries of the current user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:card).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(apps(:Cards).id, resp["app_id"])
      resp["table_objects"].each do |e|
         obj = TableObject.find_by_id(e["id"])
			assert_not_nil(obj)
			assert_equal(generate_table_object_etag(obj), e["etag"])
			assert_equal(users(:matt).id, obj.user.id)
      end
	end

	test "Can get table by id with table objects of the current user and with access" do
		cato = users(:cato)
		jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]
		expected_table_objects = [table_objects(:second), table_objects(:third), table_objects(:sixth)]

		get "/v1/apps/table/#{tables(:card).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(3, resp["table_objects"].size)

		i = 0
		expected_table_objects.each do |obj|
			assert_equal(obj.id, resp["table_objects"][i]["id"])
			assert_equal(obj.table_id, resp["table_objects"][i]["table_id"])
			assert_equal(obj.uuid, resp["table_objects"][i]["uuid"])
			assert_equal(generate_table_object_etag(obj), resp["table_objects"][i]["etag"])
			i += 1
		end
	end
	
	test "Can get the table by id and only the entries of the current user with session jwt" do
      matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:sherlock), apps(:Cards).id, "schachmatt")
      
      get "/v1/apps/table/#{tables(:card).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(apps(:Cards).id, resp["app_id"])
      resp["table_objects"].each do |e|
         obj = TableObject.find_by_id(e["id"])
			assert_not_nil(obj)
			assert_equal(generate_table_object_etag(obj), e["etag"])
			assert_equal(users(:matt).id, obj.user.id)
      end
	end
	
	test "Can get table by id with table objects of the current user and with access with session jwt" do
		cato = users(:cato)
		jwt = generate_session_jwt(cato, devs(:sherlock), apps(:Cards).id, "123456")
		expected_table_objects = [table_objects(:second), table_objects(:third), table_objects(:sixth)]

		get "/v1/apps/table/#{tables(:card).id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(3, resp["table_objects"].size)

		i = 0
		expected_table_objects.each do |obj|
			assert_equal(obj.id, resp["table_objects"][i]["id"])
			assert_equal(obj.table_id, resp["table_objects"][i]["table_id"])
			assert_equal(obj.uuid, resp["table_objects"][i]["uuid"])
			assert_equal(generate_table_object_etag(obj), resp["table_objects"][i]["etag"])
			i += 1
		end
	end

   test "Can get the table of the app of the own dev by id from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:note).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end

	test "Can get a table by id and in pages" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		count = 1
		page = 1
		
		get "/v1/apps/table/#{tables(:card).id}?app_id=#{apps(:Cards).id}&count=#{count}&page=#{page}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_equal(count, resp["table_objects"].count)
		assert_equal(table_objects(:first).uuid, resp["table_objects"][0]["uuid"])
	end

	test "Can get the second page of a table by id" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		count = 1
		page = 2
		
		get "/v1/apps/table/#{tables(:card).id}?app_id=#{apps(:Cards).id}&count=#{count}&page=#{page}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_equal(count, resp["table_objects"].count)
		assert_equal(table_objects(:third).uuid, resp["table_objects"][0]["uuid"])
	end

	test "get_table_by_id should update the last_active fields of the user and the users_app" do
      matt = users(:matt)
      matt_cards = users_apps(:mattCards)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      old_last_active = matt.last_active
      old_users_app_last_active = matt_cards.last_active
		old_updated_at = matt.updated_at

		get "/v1/apps/table/#{tables(:card).id}?app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
      matt = User.find_by_id(matt.id)
      matt_cards = UsersApp.find_by_id(matt_cards.id)

      assert_not_equal(old_last_active, matt.last_active)
      assert_not_equal(old_users_app_last_active, matt_cards.last_active)
		assert_equal(old_updated_at, matt.updated_at)
	end
   # End get_table_by_id

   # get_table_by_id_and_auth tests
	test "Missing fields in get_table_by_id_and_auth" do
		get "/v1/apps/table/#{tables(:card).id}/auth"
		resp = JSON.parse(response.body)

		assert(response.status == 401)
		assert_equal(2101, resp["errors"][0][0])
	end

	test "Can't get table by id and auth with invalid auth" do
		get "/v1/apps/table/#{tables(:card).id}/auth", headers: {'Authorization' => 'blabla'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1101, resp["errors"][0][0])
	end

	test "Can't get not existing table by id and auth" do
		auth = generate_auth_token(devs(:sherlock))

		get "/v1/apps/table/-234/auth", headers: {'Authorization' => auth}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2804, resp["errors"][0][0])
	end

	test "Can't get table by id and auth if the app does not belong to the dev" do
		auth = generate_auth_token(devs(:sherlock))

		get "/v1/apps/table/#{tables(:note).id}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get table by id and auth" do
		auth = generate_auth_token(devs(:sherlock))

		get "/v1/apps/table/#{tables(:card).id}/auth", headers: {'Authorization' => auth}
		resp = JSON.parse(response.body)

		assert_response 200
	end
   # End get_table_by_id_and_auth tests
   
   # update_table tests
   test "Missing fields in update_table" do
      put "/v1/apps/table/#{tables(:card).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_table" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/auth/user", 
				params: {name: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end
   
   test "update_table can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:note).id}", 
				params: {name: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update the table of the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:davTable).id}", 
				params: {name: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update a table with too long name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:note).id}", 
				params: {name: "#{'n' * 220}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2305, resp["errors"][0][0])
   end
   
   test "Can't update a table with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:note).id}", 
				params: {name: "t"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2205, resp["errors"][0][0])
   end
   
   test "Can't update a table with invalid name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:note).id}", 
				params: {name: "Test name"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2501, resp["errors"][0][0])
   end
   
   test "Can get the table properties after updating" do
      new_name = "TestName"
      
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:note).id}", 
				params: {name: new_name}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(tables(:note).id, resp["id"])
      assert_equal(new_name, resp["name"])
   end
   
   test "Can't update a table of the first dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/table/#{tables(:card).id}", 
				params: {name: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End update_table tests
   
   # delete_table tests
   test "delete_table can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:note).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't delete the table of an app of another user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:davTable).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Table gets deleted" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      table_id = tables(:note).id
      
      delete "/v1/apps/table/#{table_id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(Table.find_by_id(table_id))
   end
   
   test "Can't delete tables of the first dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:card).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End delete_table tests
   
   # create_access_token tests
   test "Missing fields in create_access_token" do
      post "/v1/apps/object/1/access_token"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end
   
   test "Can't create access tokens for objects of another user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      object = table_objects(:fourth)
      
      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't create access tokens for objects of the apps of another dev" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      object = table_objects(:seventh)

      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
	end
	
	test "Can create access token" do
		matt = users(:matt)
		obj = table_objects(:first)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		post "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 201

		access_token = AccessToken.find_by_id(resp["id"])
		assert_equal(resp["token"], access_token.token)
	end

	test "Can create access token with session jwt" do
		matt = users(:matt)
		obj = table_objects(:first)
		jwt = generate_session_jwt(matt, devs(:sherlock), obj.table.app_id, "schachmatt")

		post "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 201

		access_token = AccessToken.find_by_id(resp["id"])
		assert_equal(resp["token"], access_token.token)
	end
   # End create_access_token tests

   # get_access_token tests
   test "Missing fields in get_access_token" do
      get "/v1/apps/object/1/access_token"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can get access token" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:sixth)

      get "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_not_nil(resp["access_token"][0]["id"])
	end
	
	test "Can get access token with session jwt" do
      sherlock = users(:sherlock)
		obj = table_objects(:sixth)
		jwt = generate_session_jwt(sherlock, devs(:sherlock), obj.table.app_id, "sherlocked")

      get "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_not_nil(resp["access_token"][0]["id"])
   end

   test "Can't get access token of object of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:third)

      get "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't get access token of object of the app of another dev" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:seventh)

      get "/v1/apps/object/#{obj.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End get_access_token

   # add_access_token_to_object tests
   test "Missing fields in add_access_token_to_object" do
      put "/v1/apps/object/1/access_token/token"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can add access token to object" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:sixth)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 200
		assert_equal(access_token.id, resp["id"])
		assert_equal(access_token.token, resp["token"])
	end
	
	test "Can add access token to object with session jwt" do
      sherlock = users(:sherlock)
      access_token = access_tokens(:first_test_token)
		object = table_objects(:sixth)
		jwt = generate_session_jwt(sherlock, devs(:sherlock), object.table.app_id, "sherlocked")

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 200
		assert_equal(access_token.id, resp["id"])
		assert_equal(access_token.token, resp["token"])
   end

   test "Can't add access token to object of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:third)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't add access token to object of the table of another dev" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:seventh)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End add_access_token_to_object tests

   # remove_access_token_from_object tests
   test "Missing fields in remove_access_token_from_object" do
      put "/v1/apps/object/1/access_token/token"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Access token will be destroyed in remove_access_token_from_object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object = table_objects(:third)

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Remove the access token from the object and check if the access token was deleted
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => jwt}
      assert_response 200
      
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp3 = JSON.parse response.body
      assert_response 403
	end
	
	test "Access token will be destroyed in remove_access_token_from_object with session jwt" do
      matt = users(:matt)
		object = table_objects(:third)
		jwt = generate_session_jwt(matt, devs(:sherlock), object.table.app_id, "schachmatt")

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Remove the access token from the object and check if the access token was deleted
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => jwt}
      assert_response 200
      
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp3 = JSON.parse response.body
      assert_response 403
   end

   test "Can't remove access token from object of another user" do
      matt = users(:matt)
      matt_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object = table_objects(:third)
      sherlock = users(:sherlock)
      sherlock_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => matt_jwt}
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Try to remove the access token as another user
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => sherlock_jwt}
      resp3 = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp3["errors"][0][0])

      # Remove the access token
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => matt_jwt}
      assert_response 200
   end

   test "Can't remove access token from object of the table of another dev" do
      matt = users(:matt)
      mattXmatt_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      mattXsherlock_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object = table_objects(:eight)

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token", headers: {'Authorization' => mattXmatt_jwt}
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Try to remove the access token with another jwt
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => mattXsherlock_jwt}
      resp3 = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp3["errors"][0][0])

      # Remove the access token
      delete "/v1/apps/object/#{object.id}/access_token/#{token}", headers: {'Authorization' => mattXmatt_jwt}
      assert_response 200
   end
   # End remove_access_token_from_object tests
   
   # users_apps tests
   test "UsersApp object will be created when the user creates a table object" do
      tester = users(:tester)
      jwt = (JSON.parse login_user(tester, "testpassword", devs(:sherlock)).body)["jwt"]
      
      assert_nil(UsersApp.find_by(user_id: tester.id))
		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}",  
				params: {"page1": "Hello World", "page2": "Hallo Welt"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse(response.body)
      
      object_id = resp["id"]
      assert_response 201
      assert_not_nil(UsersApp.find_by(user_id: tester.id))
   end
	# End users_apps tests

	# create_notification tests
	test "Missing fields in create_notification" do
		post "/v1/apps/notification"
		resp = JSON.parse response.body

		assert(response.status == 400 || response.status ==  401)
		assert_equal(2102, resp["errors"][0][0])
		assert_equal(2110, resp["errors"][1][0])
		assert_equal(2121, resp["errors"][2][0])
	end

	test "Can't create a notification for the app of another dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/notification?app_id=#{apps(:davApp).id}&time=123213123", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create a notification when using another Content-Type than application/json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		time = 1231312
		interval = 121221

		post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&interval=#{interval}",
            params: {test: "testvalue"}.to_json,
            headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can create a notification with interval and body" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		time = 1231312
		interval = 121221
		first_property_name = "test"
		first_property_value = "testvalue"
		second_property_name = "bla"
		second_property_value = "testtest"

		post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&interval=#{interval}",
            params: {"#{first_property_name}": first_property_value, "#{second_property_name}": second_property_value}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

      assert_response 201

		notification = Notification.find_by_id(resp["id"])
      assert_not_nil(notification)
      assert_not_nil(resp["uuid"])
		assert_equal(interval, resp["interval"])

		first_property = notification.notification_properties.first
		second_property = notification.notification_properties.second

		assert_equal(first_property_name, first_property.name)
		assert_equal(first_property_value, first_property.value)
		assert_equal(second_property_name, second_property.name)
		assert_equal(second_property_value, second_property.value)
   end
   
   test "Can create a notification with uuid" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      time = Time.now.to_i
      uuid = SecureRandom.uuid

      post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&uuid=#{uuid}",
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      notification = Notification.find_by_id(resp["id"])
      assert_not_nil(notification)
      assert_equal(0, notification.interval)
      assert_equal(time, notification.time.to_time.to_i)
      assert_equal(uuid, notification.uuid)
   end

   test "Can create a notification with uuid and session jwt" do
		matt = users(:matt)
		app = apps(:TestApp)
      jwt = generate_session_jwt(matt, devs(:matt), app.id, "schachmatt")
      time = Time.now.to_i
      uuid = SecureRandom.uuid

      post "/v1/apps/notification?app_id=#{app.id}&time=#{time}&uuid=#{uuid}",
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      notification = Notification.find_by_id(resp["id"])
      assert_not_nil(notification)
      assert_equal(0, notification.interval)
      assert_equal(time, notification.time.to_time.to_i)
      assert_equal(uuid, notification.uuid)
   end

   test "Can't create a notification with uuid that is already in use" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      time = Time.now.to_i
      uuid = notifications(:TestNotification).uuid

      post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&uuid=#{uuid}",
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(2704, resp["errors"][0][0])
   end

   test "Can't create a notification with too long property name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      uuid = SecureRandom.uuid
      time = Time.now.to_i
      interval = 20000

      post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&interval=#{interval}&uuid=#{uuid}",
            params: {"#{'hello' * 100}": "testtest"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
		assert_response 400
		assert_equal(2306, resp["errors"][0][0])
   end

   test "Can't create a notification with too long property value" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      uuid = SecureRandom.uuid
      time = Time.now.to_i
      interval = 20000

      post "/v1/apps/notification?app_id=#{apps(:TestApp).id}&time=#{time}&interval=#{interval}&uuid=#{uuid}",
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
            params: {testkey: "#{'a' * 65100}"}.to_json
      resp = JSON.parse response.body
      
      assert_response 400
		assert_equal(2307, resp["errors"][0][0])
   end
   # End create_notification tests

   # get_notification tests
   test "Missing fields in get_notification" do
      get "/v1/apps/notification/bla"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get a notification that does not exist" do
      uuid = SecureRandom.uuid
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/apps/notification/#{uuid}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 404
      assert_equal(2812, resp["errors"][0][0])
	end
	
	test "Can't get the notification of another user" do
		sherlock = users(:sherlock)
		notification = notifications(:TestNotification)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

		get "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get a notification" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      notification = notifications(:TestNotification)
      firstProperty = notification_properties(:TestNotificationFirstProperty)
      secondProperty = notification_properties(:TestNotificationSecondProperty)

		get "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(notification.id, resp["id"])
		assert_equal(notification.uuid, resp["uuid"])
		assert_equal(notification.time.to_i, resp["time"])
      assert_equal(notification.interval, resp["interval"])
      
      # Check the properties
		assert_equal(firstProperty.value, resp["properties"][firstProperty.name])
		assert_equal(secondProperty.value, resp["properties"][secondProperty.name])
	end

	test "Can get a notification with session jwt" do
		matt = users(:matt)
      notification = notifications(:TestNotification)
      firstProperty = notification_properties(:TestNotificationFirstProperty)
      secondProperty = notification_properties(:TestNotificationSecondProperty)
		jwt = generate_session_jwt(matt, devs(:matt), notification.app_id, "schachmatt")

		get "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(notification.id, resp["id"])
		assert_equal(notification.uuid, resp["uuid"])
		assert_equal(notification.time.to_i, resp["time"])
      assert_equal(notification.interval, resp["interval"])
      
      # Check the properties
		assert_equal(firstProperty.value, resp["properties"][firstProperty.name])
		assert_equal(secondProperty.value, resp["properties"][secondProperty.name])
	end
   # End get_notification tests
   
   # get_all_notifications tests
   test "Missing fields in get_all_notifications" do
      get "/v1/apps/notifications"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
      assert_equal(2110, resp["errors"][1][0])
	end
	
	test "get_all_notifications should return all notifications of the app and user" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification1 = notifications(:TestNotification)
      notification2 = notifications(:TestNotification2)
      notification1FirstProperty = notification_properties(:TestNotificationFirstProperty)
      notification1SecondProperty = notification_properties(:TestNotificationSecondProperty)
      notification2FirstProperty = notification_properties(:TestNotification2FirstProperty)
      notification2SecondProperty = notification_properties(:TestNotification2SecondProperty)

		get "/v1/apps/notifications?app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

		assert_response 200
		assert_equal(notification1.id, resp["notifications"][1]["id"])
		assert_equal(notification1.uuid, resp["notifications"][1]["uuid"])
		assert_equal(notification1.time.to_i, resp["notifications"][1]["time"])
		assert_equal(notification1.interval, resp["notifications"][1]["interval"])

      assert_equal(notification1FirstProperty.value, resp["notifications"][1]["properties"][notification1FirstProperty.name])
      assert_equal(notification1SecondProperty.value, resp["notifications"][1]["properties"][notification1SecondProperty.name])

		assert_equal(notification2.id, resp["notifications"][0]["id"])
		assert_equal(notification2.uuid, resp["notifications"][0]["uuid"])
		assert_equal(notification2.time.to_i, resp["notifications"][0]["time"])
		assert_equal(notification2.interval, resp["notifications"][0]["interval"])

      assert_equal(notification2FirstProperty.value, resp["notifications"][0]["properties"][notification2FirstProperty.name])
      assert_equal(notification2SecondProperty.value, resp["notifications"][0]["properties"][notification2SecondProperty.name])
	end

	test "get_all_notifications with session jwt should return all notifications of the app and user" do
		matt = users(:matt)
		notification1 = notifications(:TestNotification)
      notification2 = notifications(:TestNotification2)
      notification1FirstProperty = notification_properties(:TestNotificationFirstProperty)
      notification1SecondProperty = notification_properties(:TestNotificationSecondProperty)
      notification2FirstProperty = notification_properties(:TestNotification2FirstProperty)
		notification2SecondProperty = notification_properties(:TestNotification2SecondProperty)
		jwt = generate_session_jwt(matt, devs(:matt), notification1.app_id, "schachmatt")

		get "/v1/apps/notifications?app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

		assert_response 200
		assert_equal(notification1.id, resp["notifications"][1]["id"])
		assert_equal(notification1.uuid, resp["notifications"][1]["uuid"])
		assert_equal(notification1.time.to_i, resp["notifications"][1]["time"])
		assert_equal(notification1.interval, resp["notifications"][1]["interval"])

      assert_equal(notification1FirstProperty.value, resp["notifications"][1]["properties"][notification1FirstProperty.name])
      assert_equal(notification1SecondProperty.value, resp["notifications"][1]["properties"][notification1SecondProperty.name])

		assert_equal(notification2.id, resp["notifications"][0]["id"])
		assert_equal(notification2.uuid, resp["notifications"][0]["uuid"])
		assert_equal(notification2.time.to_i, resp["notifications"][0]["time"])
		assert_equal(notification2.interval, resp["notifications"][0]["interval"])

      assert_equal(notification2FirstProperty.value, resp["notifications"][0]["properties"][notification2FirstProperty.name])
      assert_equal(notification2SecondProperty.value, resp["notifications"][0]["properties"][notification2SecondProperty.name])
	end

	test "Can't get the notifications of the app of another dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		get "/v1/apps/notifications?app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end
	# End get_all_notifications tests
	
	# update_notification tests
	test "Missing fields in update_notification" do
		notification = notifications(:TestNotification)

		put "/v1/apps/notification/#{notification.uuid}"
		resp = JSON.parse response.body

		assert(response.status == 400 || response.status ==  401)
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can update a notification" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		new_time = Time.now.to_i
		new_interval = 123123

		put "/v1/apps/notification/#{notification.uuid}?time=#{new_time}&interval=#{new_interval}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(new_time, resp["time"])
		assert_equal(new_interval, resp["interval"])
	end

	test "Can update a notification with session jwt" do
		matt = users(:matt)
		notification = notifications(:TestNotification)
		jwt = generate_session_jwt(matt, devs(:matt), notification.app_id, "schachmatt")
		new_time = Time.now.to_i
		new_interval = 123123

		put "/v1/apps/notification/#{notification.uuid}?time=#{new_time}&interval=#{new_interval}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(new_time, resp["time"])
		assert_equal(new_interval, resp["interval"])
	end

	test "Can update the properties of a notification" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = notification_properties(:TestNotificationFirstProperty).name
		first_property_value = "updated title"
		second_property_name = notification_properties(:TestNotificationSecondProperty).name
		second_property_value = "updated message"
		third_property_name = "new_key"
		third_property_value = "Hello World!"

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
				params: {"#{first_property_name}": first_property_value, "#{second_property_name}": second_property_value, "#{third_property_name}": third_property_value}.to_json
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(first_property_value, resp["properties"][first_property_name])
		assert_equal(second_property_value, resp["properties"][second_property_name])
		assert_equal(third_property_value, resp["properties"][third_property_name])
	end

	test "update_notification returns all properties of the notification" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = notification_properties(:TestNotificationFirstProperty).name
		first_property_value = "updated title"
		second_property_name = notification_properties(:TestNotificationSecondProperty).name
		second_property_value = notification_properties(:TestNotificationSecondProperty).value

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
				params: {"#{first_property_name}": first_property_value}.to_json
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(first_property_value, resp["properties"][first_property_name])
		assert_equal(second_property_value, resp["properties"][second_property_name])
	end

	test "update_notification removes existing property when the value is empty" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = "title"
		second_property_name = notification_properties(:TestNotificationSecondProperty).name
		second_property_value = notification_properties(:TestNotificationSecondProperty).value
		
		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
				params: {"#{first_property_name}": ""}.to_json
		resp = JSON.parse response.body

		assert_response 200
		assert_nil(resp["properties"][first_property_name])
	end

	test "Can't update the property of a notification with too long property value" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = notification_properties(:TestNotificationFirstProperty).name

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
				params: {"#{first_property_name}": "#{'a' * 65100}"}.to_json
		resp = JSON.parse response.body

		assert_response 400
		assert_equal(2307, resp["errors"][0][0])
	end

	test "Can't update a notification with too long property name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = notification_properties(:TestNotificationFirstProperty).name

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'},
				params: {"#{'test' * 100}": "blabla"}.to_json
		resp = JSON.parse response.body

		assert_response 400
		assert_equal(2306, resp["errors"][0][0])
	end

	test "Can't update a notification when using another Content-Type than application/json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		notification = notifications(:TestNotification)
		first_property_name = notification_properties(:TestNotificationFirstProperty).name

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt},
				params: {"#{first_property_name}": "blabla"}.to_json
		resp = JSON.parse response.body

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't update a notification that does not exist" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		uuid = SecureRandom.uuid
		property_name = "title"
		property_value ="Test"

		put "/v1/apps/notification/#{uuid}",
				headers: {'Authorization' => jwt},
				params: {"#{property_name}": property_value}.to_json
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2812, resp["errors"][0][0])
	end

	test "Can't update the notification of another user" do
		sherlock = users(:sherlock)
		notification = notifications(:TestNotification)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		property_name = "title"
		property_value ="Test"

		put "/v1/apps/notification/#{notification.uuid}",
				headers: {'Authorization' => jwt},
				params: {"#{property_name}": property_value}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end
	# End update_notification tests

   # delete_notification tests
   test "Missing fields in delete_notification" do
      delete "/v1/apps/notification/bla"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't delete a notification that does not exist" do
      uuid = SecureRandom.uuid
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      delete "/v1/apps/notification/#{uuid}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 404
      assert_equal(2812, resp["errors"][0][0])
   end

	test "Can't delete the notification of another user" do
		sherlock = users(:sherlock)
		notification = notifications(:TestNotification)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

		delete "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

   test "Can delete a notification" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      notification = notifications(:TestNotification)
		
		delete "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
	end
	
	test "Can delete a notification with session jwt" do
		matt = users(:matt)
		notification = notifications(:TestNotification)
		jwt = generate_session_jwt(matt, devs(:matt), notification.app_id, "schachmatt")
		
		delete "/v1/apps/notification/#{notification.uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
   end
   # End delete_notification tests
   
   # create_subscription tests
   test "Missing fields in create_subscription" do
      post "/v1/apps/subscription"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't create a subscription when using another Content-Type than application/json" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end

   test "Can't create a subscription without endpoint" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription",
            params: {p256dh: "blabla", auth: "blabla"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(2122, resp["errors"][0][0])
   end

   test "Can't create a subscription without p256dh" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription",
            params: {endpoint: "blabla", auth: "blabla"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(2123, resp["errors"][0][0])
   end

   test "Can't create a subscription without auth" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription",
            params: {endpoint: "blabla", p256dh: "blabla"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(2101, resp["errors"][0][0])
   end

   test "Can create a subscription" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      endpoint = "https://endpoint.tech/"
      p256dh = "somekey"
      auth = "someauthtoken"

      post "/v1/apps/subscription",
            params: {endpoint: endpoint, p256dh: p256dh, auth: auth}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(endpoint, resp["endpoint"])
      assert_equal(p256dh, resp["p256dh"])
      assert_equal(auth, resp["auth"])
	end
	
	test "Can create a subscription with session jwt" do
      matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:matt), apps(:TestApp).id, "schachmatt")
      endpoint = "https://endpoint.tech/"
      p256dh = "somekey"
      auth = "someauthtoken"

      post "/v1/apps/subscription",
            params: {endpoint: endpoint, p256dh: p256dh, auth: auth}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(endpoint, resp["endpoint"])
      assert_equal(p256dh, resp["p256dh"])
      assert_equal(auth, resp["auth"])
   end

   test "Can create a subscription with uuid" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      uuid = SecureRandom.uuid
      endpoint = "https://endpoint.tech/"
      p256dh = "somekey"
      auth = "someauthtoken"

      post "/v1/apps/subscription?uuid=#{uuid}",
            params: {endpoint: endpoint, p256dh: p256dh, auth: auth}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(uuid, resp["uuid"])
      assert_equal(endpoint, resp["endpoint"])
      assert_equal(p256dh, resp["p256dh"])
      assert_equal(auth, resp["auth"])
   end
   # End create_subscription tests

   # get_subscription tests
   test "Missing fields in get_subscription" do
		get "/v1/apps/subscription/bla"
		resp = JSON.parse response.body

		assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
	end
	
	test "Can't get a subscription that does not exist" do
		uuid = SecureRandom.uuid
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 404
		assert_equal(2813, resp["errors"][0][0])
	end

	test "Can't get the subscription of another user" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid
		
		get "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get a subscription" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		get "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(subscription.id, resp["id"])
		assert_equal(subscription.uuid, resp["uuid"])
		assert_equal(subscription.endpoint, resp["endpoint"])
		assert_equal(subscription.p256dh, resp["p256dh"])
		assert_equal(subscription.auth, resp["auth"])
	end

	test "Can get a subscription with session jwt" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:matt), apps(:TestApp).id, "schachmatt")
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		get "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
		assert_equal(subscription.id, resp["id"])
		assert_equal(subscription.uuid, resp["uuid"])
		assert_equal(subscription.endpoint, resp["endpoint"])
		assert_equal(subscription.p256dh, resp["p256dh"])
		assert_equal(subscription.auth, resp["auth"])
	end
   # End get_subscription tests

   # delete_subscription tests
   test "Missing fields in delete_subscription" do
      subscription = web_push_subscriptions(:MattsFirstSubscription)
      uuid = subscription.uuid

      delete "/v1/apps/subscription/#{uuid}"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't delete a subscription that does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      uuid = SecureRandom.uuid

      delete "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 404
      assert_equal(2813, resp["errors"][0][0])
   end

   test "Can't delete the subscription of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      subscription = web_push_subscriptions(:MattsFirstSubscription)
      uuid = subscription.uuid

      delete "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
	end
	
	test "Can delete a subscription" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		delete "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
	end

	test "Can delete a subscription with session jwt" do
		matt = users(:matt)
		jwt = generate_session_jwt(matt, devs(:matt), apps(:TestApp).id, "schachmatt")
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		delete "/v1/apps/subscription/#{uuid}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 200
	end
   # End delete_subscription tests
end