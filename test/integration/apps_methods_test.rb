require 'test_helper'

class AppsMethodsTest < ActionDispatch::IntegrationTest
   setup do
      save_users_and_devs
   end
   
   # Tests for create_app
   test "Missing fields in create_app" do
      post "/v1/apps/app"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 3)
   end
   
   test "Dev does not exist in create_app" do
      matt = users(:matt)
      
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      sherlock = devs(:sherlock)
      sherlock.destroy!
      
      post "/v1/apps/app?name=Test&desc=Hello World", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_same(resp["errors"][0][0], 2802)
   end
   
   test "Can't create an app from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/app?name=Test&desc=Hello World", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "Can't create an app with too short name and description" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/app?name=s&desc=s", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2203)
      assert_same(resp["errors"][1][0], 2204)
   end
   
   test "Can't create an app with too long name and description" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/app?name=#{"o"*35}&desc=" + "o"*510, headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2303)
      assert_same(resp["errors"][1][0], 2304)
   end
   
   test "Can create and delete app from website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      testapp_name = "testapp1231"
      testapp_desc = "asdasdasdasdasd"
      
      post "/v1/apps/app?name=#{testapp_name}&desc=#{testapp_desc}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(testapp_name, resp["name"])
      assert_equal(testapp_desc, resp["description"])
      
      delete "/v1/apps/app/#{resp["id"]}", headers: {'Authorization' => jwt}
      resp2 = JSON.parse response.body
      
      assert_response 200
   end

   test "Can create app with links" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      testapp_name = "testapp11231"
      testapp_desc = "asdasdasdasd"
      link_web = "http://dav-apps.tech"
      link_play = "http://dav-apps.tech"

      post "/v1/apps/app?name=#{testapp_name}&desc=#{testapp_desc}&link_web=#{link_web}&link_play=#{link_play}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(testapp_name, resp["name"])
      assert_equal(testapp_desc, resp["description"])
      assert_equal(link_web, resp["link_web"])
      assert_equal(link_play, resp["link_play"])

      delete "/v1/apps/app/#{resp["id"]}", headers: {'Authorization' => jwt}
      resp2 = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't create app with invalid link" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      testapp_name = "testapp11231"
      testapp_desc = "asdasdasdasd"
      link_web = "blablabla"
      link_windows = "alert('Hello')"

      post "/v1/apps/app?name=#{testapp_name}&desc=#{testapp_desc}&link_web=#{link_web}&link_windows=#{link_windows}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 400
      assert_equal(resp["errors"].length, 2)
      assert_equal(resp["errors"][0][0], 2402)
      assert_equal(resp["errors"][1][0], 2404)
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
      assert_same(1102, resp["errors"][0][0])
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
      assert_same(tables(:note).id, resp["tables"][0]["id"])
   end
   
   test "Can't get an app of the first dev as another dev" do
      jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_app tests

   # get_active_users_of_app tests
   test "Missing fields in get_active_users_of_app" do
      get "/v1/apps/app/1/active_users"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_equal(1, resp["errors"].length)
	end
	
	test "Can't get active app users from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/apps/app/#{apps(:TestApp).id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_same(1102, resp["errors"][0][0])
	end

	test "Can't get the active app users of the app of another dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		get "/v1/apps/app/#{apps(:Cards).id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get the active app users" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		# Create active app users
		first_active_user = ActiveAppUser.create(app: app,
										time: (Time.now - 1.days).beginning_of_day,
										count_daily: 1, 
										count_monthly: 5,
										count_yearly: 17)
		second_active_user = ActiveAppUser.create(app: app,
									time: (Time.now - 3.days).beginning_of_day,
									count_daily: 6, 
									count_monthly: 9,
									count_yearly: 20)

		get "/v1/apps/app/#{app.id}/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

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

	test "Can get active app users in the specified timeframe" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_active_user = active_app_users(:first_active_testapp_user)
		second_active_user = active_app_users(:second_active_testapp_user)

		get "/v1/apps/app/#{app.id}/active_users?start=#{start_timestamp}&end=#{end_timestamp}", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

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
   # End get_active_users_of_app tests

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
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2203)
      assert_same(resp["errors"][1][0], 2204)
   end
   
   test "Can't update the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "Can't update the app of the first dev as another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
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
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2403, resp["errors"][0][0])
      assert_same(2404, resp["errors"][1][0])
   end
   # End update_app tests
   
   # delete_app tests
   test "Missing fields in delete_app" do
      delete "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "delete_app can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   # End delete_app tests
   
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
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with too long table_name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{"n"*220}&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with an invalid table_name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=New Table name&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json, 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
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
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create an empty object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2116, resp["errors"][0][0])
   end
   
   test "Can't create an object with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				params: {"": "a"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
   end
   
   test "Can't create an object with too long name and value" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", 
				params: {"#{'n' * 220}": "#{'n' * 65500}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can't create object with visibility > 2" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=5&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility < 0" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=-4&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility that is not an integer" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=hello&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can create object with another visibility" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", 
				params: {"test": "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(2, resp["visibility"])
   end

   test "Can't create object and upload file without ext parameter" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		post "/v1/apps/object?table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", 
				params: "Hallo Welt! Dies wird eine Textdatei.", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 415
      assert_same(1104, resp["errors"][0][0])
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
      assert_same(1104, resp["errors"][0][0])
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
      assert_same(2704, resp["errors"][0][0])
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
      assert_same(1102, resp["errors"][0][0])
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
		assert_same(1102, resp["errors"][0][0])
	end
   # End create_object tests
   
   # get_object tests
   test "Can't get a table object that does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/-20", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 404
      assert_same(2805, resp["errors"][0][0])
   end
   
   test "Can't get the objects of the tables of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:sixth).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
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
   
   test "Can't access an object when the user does not own the object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:second).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get object without access token and JWT" do
      get "/v1/apps/object/#{table_objects(:second).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2102, resp["errors"][0][0])
      assert_same(2117, resp["errors"][1][0])
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
   
   # update_object tests
   test "Can't update an object when the user does not own the object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:dav)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:second).id}", 
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update an object with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}", 
				params: {"": "a"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
   end
   
   test "Can't update an object with too long name and value" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}", 
				params: {"#{'n' * 220}": "#{'n' * 65500}"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
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
      assert_same(2, resp["visibility"])
   end
   
   test "Can't update an object with invalid visibility" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
		put "/v1/apps/object/#{table_objects(:first).id}?visibility=hello", 
				params: {test: "test"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(0, resp["visibility"])
   end

	test "Can't update object without content type header" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		put "/v1/apps/object/#{table_objects(:third).uuid}", 
				params: {page1: "test", page2: "test2"}.to_json,
				headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 415
		assert_same(1104, resp["errors"][0][0])
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
	
	test "update_object does not create a new property when the value is empty" do
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

	test "update_object removes existing property when the value is empty" do
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
      assert_same(1102, resp["errors"][0][0])
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
   
   # create_table tests
   test "Missing fields in create_table" do
      post "/v1/apps/table"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
      assert_same(2110, resp["errors"][1][0])
      assert_same(2113, resp["errors"][2][0])
   end
   
   test "Can't create a table for the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=NewTable&app_id=#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can create a table for an app that the dev owns" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=NewTable&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(apps(:TestApp).id, resp["app_id"])
      assert_not_nil(resp["name"])
      assert_not_nil(resp["id"])
   end
   
   test "Can create a table from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/table?table_name=NewTable&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(apps(:TestApp).id, resp["app_id"])
   end
   
   test "Can't create a table for an app of the first dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=NewTable&app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create a table with too long name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=#{"n"*220}&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't create a table with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=n&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2205, resp["errors"][0][0])
   end
   
   test "Can't create a table with invalid name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?table_name=Hello World&app_id=#{apps(:TestApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2501, resp["errors"][0][0])
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
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the table of the app of another dev from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get the table and only the entries of the current user" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(apps(:Cards).id, resp["app_id"])
      resp["table_objects"].each do |e|
			obj = TableObject.find_by_id(e["id"])
			assert_not_nil(obj)
			assert_equal(generate_table_object_etag(obj), e["etag"])
			assert_equal(users(:matt).id, obj.user.id)
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
			assert_same(users(:matt).id, obj.user.id)
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
			assert_same(users(:matt).id, obj.user.id)
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
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:sherlock)).body)["jwt"]
      
      assert_nil(UsersApp.find_by(user_id: tester2.id))
		post "/v1/apps/object?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}",  
				params: {"page1": "Hello World", "page2": "Hallo Welt"}.to_json,
				headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      object_id = resp["id"]
      assert_response 201
      assert_not_nil(UsersApp.find_by(user_id: tester2.id))
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
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can't create a subscription when using another Content-Type than application/json" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end

   test "Can't create a subscription without endpoint" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription?jwt=#{jwt}",
            params: '{"p256dh": "blabla", "auth": "blabla"}',
            headers: {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2122, resp["errors"][0][0])
   end

   test "Can't create a subscription without p256dh" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription?jwt=#{jwt}",
            params: '{"endpoint": "blabla", "auth": "blabla"}',
            headers: {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2123, resp["errors"][0][0])
   end

   test "Can't create a subscription without auth" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/subscription?jwt=#{jwt}",
            params: '{"endpoint": "blabla", "p256dh": "blabla"}',
            headers: {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2101, resp["errors"][0][0])
   end

   test "Can create a subscription" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      endpoint = "https://endpoint.tech/"
      p256dh = "somekey"
      auth = "someauthtoken"

      post "/v1/apps/subscription?jwt=#{jwt}",
            params: '{"endpoint": "' + endpoint + '", "p256dh": "' + p256dh + '", "auth": "' + auth + '"}',
            headers: {'Content-Type' => 'application/json'}
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

      post "/v1/apps/subscription?jwt=#{jwt}&uuid=#{uuid}",
            params: '{"endpoint": "' + endpoint + '", "p256dh": "' + p256dh + '", "auth": "' + auth + '"}',
            headers: {'Content-Type' => 'application/json'}
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
      assert_same(2102, resp["errors"][0][0])
	end
	
	test "Can't get a subscription that does not exist" do
		uuid = SecureRandom.uuid
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

		get "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
		resp = JSON.parse response.body

		assert_response 404
		assert_same(2813, resp["errors"][0][0])
	end

	test "Can't get the subscription of another user" do
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid
		
		get "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
		resp = JSON.parse response.body

		assert_response 403
		assert_same(1102, resp["errors"][0][0])
	end

	test "Can get a subscription" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		get "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
		resp = JSON.parse response.body

		assert_response 200
		assert_same(subscription.id, resp["id"])
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
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can't delete a subscription that does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      uuid = SecureRandom.uuid

      delete "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 404
      assert_same(2813, resp["errors"][0][0])
   end

   test "Can't delete the subscription of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      subscription = web_push_subscriptions(:MattsFirstSubscription)
      uuid = subscription.uuid

      delete "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
	end
	
	test "Can delete a subscription" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		subscription = web_push_subscriptions(:MattsFirstSubscription)
		uuid = subscription.uuid

		delete "/v1/apps/subscription/#{uuid}?jwt=#{jwt}"
		resp = JSON.parse response.body

		assert_response 200
	end
   # End delete_subscription tests
end