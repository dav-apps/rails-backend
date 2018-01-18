require 'test_helper'

class AppsMethodsTest < ActionDispatch::IntegrationTest
   
   # Tests for create_app
   test "Missing fields in create_app" do
      post "/v1/apps/app"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 3)
   end
   
   test "Dev does not exist in create_app" do
      save_users_and_devs
      
      matt = users(:matt)
      
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      sherlock = devs(:sherlock)
      sherlock.destroy!
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=Test&desc=Hello World"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"][0][0], 2802)
   end
   
   test "can't create an app from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=Test&desc=Hello World"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "can't create an app with too short name and description" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=s&desc=s"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2203)
      assert_same(resp["errors"][1][0], 2204)
   end
   
   test "can't create an app with too long name and description" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=#{"o"*35}&desc=" + "o"*510
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2303)
      assert_same(resp["errors"][1][0], 2304)
   end
   
   test "Can create and delete app from website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      testapp_name = "testapp1231"
      testapp_desc = "asdasdasdasdasd"
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=#{testapp_name}&desc=#{testapp_desc}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(testapp_name, resp["name"])
      assert_equal(testapp_desc, resp["description"])
      
      
      delete "/v1/apps/app/#{resp["id"]}?jwt=#{matts_jwt}"
      resp2 = JSON.parse response.body
      
      assert_response 200
   end

   test "Can create app with links" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      testapp_name = "testapp11231"
      testapp_desc = "asdasdasdasd"
      link_web = "http://dav-apps.tech"
      link_play = "http://dav-apps.tech"

      post "/v1/apps/app?jwt=#{matts_jwt}&name=#{testapp_name}&desc=#{testapp_desc}&link_web=#{link_web}&link_play=#{link_play}"
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(testapp_name, resp["name"])
      assert_equal(testapp_desc, resp["description"])
      assert_equal(link_web, resp["link_web"])
      assert_equal(link_play, resp["link_play"])


      delete "/v1/apps/app/#{resp["id"]}?jwt=#{matts_jwt}"
      resp2 = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't create app with invalid link" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      testapp_name = "testapp11231"
      testapp_desc = "asdasdasdasd"
      link_web = "blablabla"
      link_windows = "alert('Hello')"

      post "/v1/apps/app?jwt=#{matts_jwt}&name=#{testapp_name}&desc=#{testapp_desc}&link_web=#{link_web}&link_windows=#{link_windows}"
      resp = JSON.parse response.body

      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2402)
      assert_same(resp["errors"][1][0], 2404)
   end
   # End create_app tests
   
   
   # Tests for get_app
   test "Missing fields in get_app" do
      save_users_and_devs
      
      get "/v1/apps/app/#{apps(:Cards).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end
   
   test "App does not exist in get_app" do
      save_users_and_devs
      cards_id = apps(:Cards).id
      apps(:Cards).destroy!
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{cards_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 404
      assert_same(2803, resp["errors"][0][0])
   end
   
   test "get_app can't be called from outside the website" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:dav)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "get_app can be called from the appropriate dev" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get the tables of the app" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(tables(:note).id, resp["tables"][0]["id"])
   end
   
   test "Can't get an app of the first dev as another dev" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:Cards).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_app tests

   # Tests for get_all_apps
   test "Missing fields in get_all_apps" do
      save_users_and_devs
      
      get "/v1/apps/apps/all"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end

   test "Can get all apps from the website" do
      save_users_and_devs
      
      auth = generate_auth_token(devs(:sherlock))
      
      get "/v1/apps/apps/all?auth=#{auth}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get all apps from outside the website" do
      save_users_and_devs
      
      auth = generate_auth_token(devs(:matt))
      
      get "/v1/apps/apps/all?auth=#{auth}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_all_apps tests
   
   # update_app tests
   test "Missing fields in update_app" do
      save_users_and_devs
      
      put "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end
   
   test "Can't use another content type but json in update_app" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"test\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "User does not exist in update_app" do
      save_users_and_devs
      matt_id = users(:matt).id
      test_app_id = apps(:TestApp).id
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      users(:matt).destroy!
      
      put "/v1/apps/app/#{test_app_id}?jwt=#{matts_jwt}", "{\"name\":\"TestApp12133\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2801, resp["errors"][0][0])
   end
   
   test "update_app can't be called from outside the website" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"name\":\"TestApp121314\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update an app with too long name and description" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"name\":\"#{"o"*35}\", \"description\":\"#{"o"*510}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2303)
      assert_same(resp["errors"][1][0], 2304)
   end
   
   test "can't update an app with too short name and description" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"name\":\"a\", \"description\":\"a\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2203)
      assert_same(resp["errors"][1][0], 2204)
   end
   
   test "Can't update the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:davApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "Can't update the app of the first dev as another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:Cards).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can update name and description of app at once" do
      save_users_and_devs
      
      new_name = "Neuer Name"
      new_desc = "Neue Beschreibung"
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"name\":\"#{new_name}\", \"description\": \"#{new_desc}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(new_name, resp["name"])
      assert_equal(new_desc, resp["description"])
   end

   test "Can update links of an app" do
      save_users_and_devs

      link_play = "https://dav-apps.tech"
      link_windows = "http://microsoft.com/blabla"

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"link_play\":\"#{link_play}\", \"link_windows\": \"#{link_windows}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(link_play, resp["link_play"])
      assert_equal(link_windows, resp["link_windows"])
   end

   test "Can update app with blank links" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"link_play\":\"_\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal("", resp["link_play"])
   end

   test "Can't update app with invalid links" do
      save_users_and_devs

      link_play = "bla  blam´a dadasd"
      link_windows = "hellowor-ld124"

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"link_play\":\"#{link_play}\", \"link_windows\": \"#{link_windows}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2403, resp["errors"][0][0])
      assert_same(2404, resp["errors"][1][0])
   end
   # End update_app tests
   
   
   # delete_app tests
   test "Missing fields in delete_app" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "delete_app can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't delete the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:davApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   # End delete_app tests
   
   
   # create_object tests
   test "Missing fields in create_object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/object"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 3)
   end
   
   test "Can't save json when using another Content-Type than json in create_object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"test\": \"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2119, resp["errors"][0][0])
   end
   
   test "Table does not exist and gets created when the user is the dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert(Table.find_by(name: "NewTable"))
   end
   
   test "Can't create a new table in create_object with too short table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=N&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with too long table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{"n"*20}&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with an invalid table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=New Table name&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   
   test "Can't create an object for the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create an empty object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", nil, {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2116, resp["errors"][0][0])
   end
   
   test "Can't create an object with too short name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"\":\"\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't create an object with too long name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"#{"n"*30}\":\"#{"n"*1202}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can't create object with visibility > 2" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=5&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility < 0" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=-4&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility that is not an integer" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=hello&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can create object with another visibility" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(2, resp["visibility"])
   end

   test "Can't create object and upload file without ext parameter" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2119, resp["errors"][0][0])
   end

   test "Can create object and upload text file" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      assert_not_nil(resp["id"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end

   test "Can create object and upload empty file" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end

   test "Can't create object and upload file with empty Content-Type header" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt"
      resp = JSON.parse response.body

      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   # End create_object tests
   
   # get_object tests
   test "TableObject does not exist" do
      save_users_and_devs
      
      object_id = table_objects(:first).id
      table_objects(:first).destroy!
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/#{object_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 404
      assert_same(2805, resp["errors"][0][0])
   end
   
   test "Can't get the objects of the tables of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:sixth).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get own object and all properties" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(table_objects(:first).id, resp["id"])
      assert_not_nil(resp["properties"]["page1"])
      assert_not_nil(resp["properties"]["page2"])
   end
   
   test "Can't access an object when the user does not own the object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get object without access token and JWT" do
      save_users_and_devs
      
      get "/v1/apps/object/#{table_objects(:second).id}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(2117, resp["errors"][0][0])
      assert_same(2102, resp["errors"][1][0])
   end
   
   test "Can get object with access token without logging in" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object_id = table_objects(:third).id
      
      post "/v1/apps/access_token?object_id=#{object_id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 201
      
      token = resp["access_token"]
      
      get "/v1/apps/object/#{object_id}?access_token=#{token}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get protected object as another user" do
      save_users_and_devs
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:first).id}?jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get protected object with uploaded file as another user" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=1&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{resp["id"]}?jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get public object as logged in user" do
      save_users_and_devs
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:eight).id}?jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get public object without being logged in" do
      save_users_and_devs
      
      get "/v1/apps/object/#{table_objects(:eight).id}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can get object with uploaded file" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201

      get "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      resp2 = response.body

      assert_response 200
      assert(!resp2.include?("id"))

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end
   # End get_object tests
   
   # update_object tests
   test "Can't update an object when the user does not own the object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:dav)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update an object with too short name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"\":\"\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't update an object with too long name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"#{"n"*30}\":\"#{"n"*1202}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can get all properties of an object after updating one" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(table_objects(:first).id, resp["id"])
      assert_not_nil(resp["properties"]["test"])
   end
   
   test "Can update object with new visibility" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}&visibility=2", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(2, resp["visibility"])
   end
   
   test "Can't update an object with invalid visibility" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}&visibility=hello", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(0, resp["visibility"])
   end

   test "Can update visibility and ext of object with file" do
      save_users_and_devs

      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      # Create object
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201

      new_ext = "html"
      new_visibility = 2

      # Update object
      put "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}&visibility=#{new_visibility}&ext=#{new_ext}", "<p>Hallo Welt! Dies ist eine HTML-Datei.</p>", {'Content-Type' => 'text/html'}
      resp = JSON.parse response.body

      assert_response 200
      assert_equal(new_ext, resp["properties"]["ext"])
      assert_equal(new_visibility, resp["visibility"])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end
   # End update_object tests
   
   # delete_object tests
   test "Can't delete an object when the dev does not own the table" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:seventh).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete an object of another user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can delete an object that the user owns" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   # End delete_object tests
   
   # create_table tests
   test "Missing fields in create_table" do
      save_users_and_devs
      
      post "/v1/apps/table"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2113, resp["errors"][0][0])
      assert_same(2110, resp["errors"][1][0])
      assert_same(2102, resp["errors"][2][0])
   end
   
   test "Can't create a table for the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:davApp).id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can create a table for an app that the dev owns" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(apps(:TestApp).id, resp["app_id"])
      assert_not_nil(resp["name"])
      assert_not_nil(resp["id"])
   end
   
   test "Can create a table from the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(apps(:TestApp).id, resp["app_id"])
   end
   
   test "Can't create a table for an app of the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:Cards).id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create a table with too long table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=#{"n"*26}&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't a table with too short table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=n&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't create a table with invalid table_name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=Hello World&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   # End create_table tests
   
   # get_table tests
   test "Missing fields in get_table" do
      get "/v1/apps/table"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2110, resp["errors"][0][0])
      assert_same(2113, resp["errors"][1][0])
      assert_same(2102, resp["errors"][2][0])
   end
   
   test "Can't get the table of the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the table of the app of another dev from the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get the table and only the entries of the current user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(apps(:Cards).id, resp["app_id"])
      resp["entries"].each do |e|
         assert_same(users(:matt).id, e["user_id"])
      end
   end
   
   test "Can get the table of the app of the own dev from the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   # End get_table tests
   
   # update_table tests
   test "Missing fields in update_table" do
      put "/v1/apps/table/#{tables(:card).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_table" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "update_table can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update the table of the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update a table with too long table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"#{"n"*30}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Can't update a table with too short table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"t\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't update a table with invalid table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"Test name\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   
   test "Can get the table properties after updating" do
      save_users_and_devs
      
      new_name = "TestName"
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"#{new_name}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(tables(:note).id, resp["id"])
      assert_equal(new_name, resp["name"])
   end
   
   test "Can't update a table of the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:card).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End update_table tests
   
   # delete_table tests
   test "delete_table can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete the table of an app of another user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Table gets deleted" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      table_id = tables(:note).id
      
      delete "/v1/apps/table/#{table_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(Table.find_by_id(table_id))
   end
   
   test "Can't delete tables of the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:card).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End delete_table tests
   
   # create_access_token tests
   test "Missing fields in create_access_token" do
      post "/v1/apps/access_token"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2115, resp["errors"][0][0])
      assert_same(2102, resp["errors"][1][0])
   end
   
   test "Can't create access tokens for objects of another user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/access_token?object_id=#{table_objects(:fifth).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create access tokens for objects of the apps of another dev" do
      save_users_and_devs
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/access_token?object_id=#{table_objects(:seventh).id}&jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End create_access_token tests
   
   # users_apps tests
   test "UsersApp object gets created and deleted when user creates object and deletes it" do
      save_users_and_devs
      
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:sherlock)).body)["jwt"]
      
      assert_nil(UsersApp.find_by(user_id: tester2.id))
      post "/v1/apps/object?jwt=#{jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", "{\"page1\":\"Hello World\", \"page2\":\"Hallo Welt\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      object_id = resp["id"]
      assert_response 201
      assert_not_nil(UsersApp.find_by(user_id: tester2.id))
      
      delete "/v1/apps/object/#{object_id}?jwt=#{jwt}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_nil(UsersApp.find_by(user_id: tester2.id))
   end
   # End users_apps tests
end