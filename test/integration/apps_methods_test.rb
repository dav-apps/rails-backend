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
      
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      sherlock = devs(:sherlock)
      sherlock.destroy!
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=Test&desc=Hello World"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"][0][0], 2802)
   end
   
   test "can't create an app from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=Test&desc=Hello World"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "can't create an app with too short name and description" do
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
      get "/v1/apps/app/#{apps(:Cards).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end
   
   test "App does not exist in get_app" do
      cards_id = apps(:Cards).id
      apps(:Cards).destroy!
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{cards_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 404
      assert_same(2803, resp["errors"][0][0])
   end
   
   test "get_app can't be called from outside the website" do
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:dav)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "get_app can be called from the appropriate dev" do
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get the tables of the app" do
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(tables(:note).id, resp["tables"][0]["id"])
   end
   
   test "Can't get an app of the first dev as another dev" do
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/app/#{apps(:Cards).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_app tests

   # Tests for get_all_apps
   test "Missing fields in get_all_apps" do
      get "/v1/apps/apps/all"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end

   test "Can get all apps from the website" do
      auth = generate_auth_token(devs(:sherlock))
      
      get "/v1/apps/apps/all?auth=#{auth}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get all apps from outside the website" do
      auth = generate_auth_token(devs(:matt))
      
      get "/v1/apps/apps/all?auth=#{auth}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_all_apps tests
   
   # update_app tests
   test "Missing fields in update_app" do
      put "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end
   
   test "Can't use another content type but json in update_app" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"test\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "User does not exist in update_app" do
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
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"name\":\"TestApp121314\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update an app with too long name and description" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:davApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "Can't update the app of the first dev as another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:Cards).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can update name and description of app at once" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}", "{\"link_play\":\"_\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal("", resp["link_play"])
   end

   test "Can't update app with invalid links" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "delete_app can't be called from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't delete the app of another dev" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/object"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 3)
   end
   
   test "Can't save json when using another Content-Type than application/json in create_object" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"test\": \"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "Table does not exist and gets created when the user is the dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert(Table.find_by(name: "NewTable"))
   end
   
   test "Can't create a new table in create_object with too short table_name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=N&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with too long table_name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{"n"*20}&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't create a new table in create_object with an invalid table_name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=New Table name&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   
   test "Can't create an object for the app of another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create an empty object" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", nil, {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2116, resp["errors"][0][0])
   end
   
   test "Can't create an object with too short name and value" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"\":\"\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't create an object with too long name and value" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"#{"n"*30}\":\"#{"n"*1202}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can't create object with visibility > 2" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=5&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility < 0" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=-4&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can't create object with visibility that is not an integer" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=hello&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(0, resp["visibility"])
   end
   
   test "Can create object with another visibility" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(2, resp["visibility"])
   end

   test "Can't create object and upload file without ext parameter" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=2&app_id=#{apps(:TestApp).id}", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end

   test "Can create object and upload text file" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt"
      resp = JSON.parse response.body

      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end

   test "Can create object with uuid" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      uuid = SecureRandom.uuid

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&uuid=#{uuid}", '{"test": "test"}', {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(resp["uuid"], uuid)
   end

   test "Can't create object with uuid that is already in use" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&uuid=#{table_objects(:third).uuid}", '{"test": "test"}', {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2704, resp["errors"][0][0])
   end

   test "Can create object with binary file" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&ext=png", body: fixture_file_upload('test/files/test.png', 'image/png', true)
      resp = JSON.parse response.body
      
      assert_response 201
      assert_equal(tables(:card).id, resp["table_id"])
      assert_not_nil(resp["properties"]["etag"])

      # Delete the object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      assert_response 200
   end

   test "Can create object with table_id" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", '{"test": "test"}', {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
   end

   test "Can create object with uuid and table_id" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      uuid = SecureRandom.uuid

      post "/v1/apps/object?jwt=#{matts_jwt}&table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}&uuid=#{uuid}", '{"test": "test"}', {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body

      assert_response 201
      assert_equal(resp["uuid"], uuid)
   end

   test "Can't create an object for the app of another dev with table_id" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_id=#{tables(:card).id}&app_id=#{apps(:Cards).id}", '{"test":"test"}', {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can create object with table_id and another visibility and upload text file" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      visibility = 1

      post "/v1/apps/object?jwt=#{matts_jwt}&table_id=#{tables(:note).id}&visibility=#{visibility}&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      assert_not_nil(resp["id"])
      assert_same(resp["visibility"], visibility)

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end
   # End create_object tests
   
   # get_object tests
   test "TableObject does not exist" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:sixth).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get own object and all properties" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
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
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object_id = table_objects(:third).id
      
      post "/v1/apps/object/#{object_id}/access_token?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 201
      
      token = resp["token"]
      
      get "/v1/apps/object/#{object_id}?access_token=#{token}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can get protected object as another user" do
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:first).id}?jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can't get protected object with uploaded file as another user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=1&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{resp["id"]}?jwt=#{sherlocks_jwt}"
      resp2 = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp2["errors"][0][0])

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
      assert_response 200
   end
   
   test "Can get public object as logged in user" do
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/object/#{table_objects(:eight).id}?jwt=#{sherlocks_jwt}"
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
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      assert_not_nil(resp["properties"]["etag"])

      get "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}&file=true"
      resp2 = response.body

      assert_response 200
      assert(!resp2.include?("id"))

      # Delete object
      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      
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
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      uuid = SecureRandom.uuid

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt&uuid=#{uuid}", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201

      get "/v1/apps/object/#{uuid}?jwt=#{matts_jwt}&file=true"
      resp2 = response.body

      assert_response 200
      assert(!resp2.include?("id"))

      # Delete object
      delete "/v1/apps/object/#{uuid}?jwt=#{matts_jwt}"
      
      assert_response 200
   end
   # End get_object tests
   
   # update_object tests
   test "Can't update an object when the user does not own the object" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:dav)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update an object with too short name and value" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"\":\"\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't update an object with too long name and value" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"#{"n"*30}\":\"#{"n"*1202}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can get all properties of an object after updating one" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(table_objects(:first).id, resp["id"])
      assert_not_nil(resp["properties"]["test"])
   end
   
   test "Can update object with new visibility" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}&visibility=2", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(2, resp["visibility"])
   end
   
   test "Can't update an object with invalid visibility" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}&visibility=hello", "{\"#{"test"}\":\"#{"test"}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(0, resp["visibility"])
   end

   test "Can update visibility and ext of object with file" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      # Create object
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&visibility=0&app_id=#{apps(:TestApp).id}&ext=txt", "Hallo Welt! Dies wird eine Textdatei.", {'Content-Type' => 'text/plain'}
      resp = JSON.parse response.body

      assert_response 201
      
      etag = resp["properties"]["etag"]
      assert_not_nil(etag)

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

   test "Can update object with uuid" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:third).uuid}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 200
   end

   test "Can update object and replace uploaded file" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      file1Path = "test/files/test.png"
      file2Path = "test/files/test2.mp3"

      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:card).name}&app_id=#{apps(:Cards).id}&ext=png", File.open(file1Path, "rb").read, {'Content-Type' => 'image/png'}
      resp = JSON.parse response.body
      
      assert_response 201
      etag = resp["properties"]["etag"]
      assert_equal(File.size(file1Path), resp["properties"]["size"].to_i)
      assert_not_nil(etag)

      put "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}&ext=mp3", File.open(file2Path, "rb").read, {'Content-Type' => 'audio/mpeg'}
      resp2 = JSON.parse response.body
      
      assert_response 200
      etag2 = resp2["properties"]["etag"]
      assert_equal(File.size(file2Path), resp2["properties"]["size"].to_i)
      assert_not_nil(etag2)
      assert(etag != etag2)

      delete "/v1/apps/object/#{resp["id"]}?jwt=#{matts_jwt}"
      assert_response 200
   end
   # End update_object tests
   
   # delete_object tests
   test "Can't delete an object when the dev does not own the table" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:seventh).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete an object of another user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:second).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can delete an object that the user owns" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end

   test "Can delete object with uuid" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:first).uuid}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   # End delete_object tests
   
   # create_table tests
   test "Missing fields in create_table" do
      post "/v1/apps/table"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2113, resp["errors"][0][0])
      assert_same(2110, resp["errors"][1][0])
      assert_same(2102, resp["errors"][2][0])
   end
   
   test "Can't create a table for the app of another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:davApp).id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can create a table for an app that the dev owns" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(apps(:TestApp).id, resp["app_id"])
   end
   
   test "Can't create a table for an app of the first dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:Cards).id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create a table with too long table_name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=#{"n"*26}&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't a table with too short table_name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/table?jwt=#{matts_jwt}&table_name=n&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't create a table with invalid table_name" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the table of the app of another dev from the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:davTable).name}&app_id=#{apps(:davApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get the table and only the entries of the current user" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table?table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   # End get_table tests

   # get_table_by_id tests
   test "Missing fields in get_table_by_id" do
      get "/v1/apps/table/#{tables(:card).id}"
      resp = JSON.parse response.body

      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can't get the table of the app of another dev by id" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get the table of the app of another dev by id from the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can get the table by id and only the entries of the current user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:card).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(apps(:Cards).id, resp["app_id"])
      resp["entries"].each do |e|
         assert_same(users(:matt).id, e["user_id"])
      end
   end

   test "Can get the table of the app of the own dev by id from the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   # End get_table_by_id
   
   # update_table tests
   test "Missing fields in update_table" do
      put "/v1/apps/table/#{tables(:card).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_table" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/auth/user?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "update_table can't be called from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update the table of the app of another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update a table with too long table name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"#{"n"*30}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Can't update a table with too short table name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"t\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't update a table with invalid table name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}", "{\"name\":\"Test name\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   
   test "Can get the table properties after updating" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete the table of an app of another user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Table gets deleted" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      table_id = tables(:note).id
      
      delete "/v1/apps/table/#{table_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(Table.find_by_id(table_id))
   end
   
   test "Can't delete tables of the first dev" do
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
      post "/v1/apps/object/1/access_token"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "Can't create access tokens for objects of another user" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      object = table_objects(:fourth)
      
      post "/v1/apps/object/#{object.id}/access_token?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't create access tokens for objects of the apps of another dev" do
      sherlock = users(:sherlock)
      sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      object = table_objects(:seventh)

      post "/v1/apps/object/#{object.id}/access_token?jwt=#{sherlocks_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End create_access_token tests

   # get_access_token tests
   test "Missing fields in get_access_token" do
      get "/v1/apps/object/1/access_token"
      resp = JSON.parse response.body

      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can get access token" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:sixth)

      get "/v1/apps/object/#{obj.id}/access_token?jwt=#{jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_not_nil(resp["access_token"][0]["id"])
   end

   test "Can't get access token of object of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:third)

      get "/v1/apps/object/#{obj.id}/access_token?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get access token of object of the app of another dev" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      obj = table_objects(:seventh)

      get "/v1/apps/object/#{obj.id}/access_token?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_access_token

   # add_access_token_to_object tests
   test "Missing fields in add_access_token_to_object" do
      put "/v1/apps/object/1/access_token/token"
      resp = JSON.parse response.body

      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can add access token to object" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:sixth)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 200
      assert_equal(access_token.id, resp["id"])
   end

   test "Can't add access token to object of another user" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:third)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't add access token to object of the table of another dev" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
      access_token = access_tokens(:first_test_token)
      object = table_objects(:seventh)

      put "/v1/apps/object/#{object.id}/access_token/#{access_token.token}?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End add_access_token_to_object tests

   # remove_access_token_from_object tests
   test "Missing fields in remove_access_token_from_objects" do
      put "/v1/apps/object/1/access_token/token"
      resp = JSON.parse response.body

      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end

   test "Access token will be destroyed in remove_access_token_from_object" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object = table_objects(:third)

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token?jwt=#{jwt}"
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Remove the access token from the object and check if the access token was deleted
      delete "/v1/apps/object/#{object.id}/access_token/#{token}?jwt=#{jwt}"
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
      post "/v1/apps/object/#{object.id}/access_token?jwt=#{matt_jwt}"
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Try to remove the access token as another user
      delete "/v1/apps/object/#{object.id}/access_token/#{token}?jwt=#{sherlock_jwt}"
      resp3 = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp3["errors"][0][0])

      # Remove the access token
      delete "/v1/apps/object/#{object.id}/access_token/#{token}?jwt=#{matt_jwt}"
      assert_response 200
   end

   test "Can't remove access token from object of the table of another dev" do
      matt = users(:matt)
      mattXmatt_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      mattXsherlock_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      object = table_objects(:eight)

      # Create new access_token and add it to an object
      post "/v1/apps/object/#{object.id}/access_token?jwt=#{mattXmatt_jwt}"
      resp = JSON.parse response.body

      assert_response 201
      token = resp["token"]

      # Try to get the object as not logged in user
      get "/v1/apps/object/#{object.id}?access_token=#{token}"
      resp2 = JSON.parse response.body
      
      assert_response 200
      assert_equal(resp2["id"], object.id)

      # Try to remove the access token with another jwt
      delete "/v1/apps/object/#{object.id}/access_token/#{token}?jwt=#{mattXsherlock_jwt}"
      resp3 = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp3["errors"][0][0])

      # Remove the access token
      delete "/v1/apps/object/#{object.id}/access_token/#{token}?jwt=#{mattXmatt_jwt}"
      assert_response 200
   end
   # End remove_access_token_from_object tests
   
   # users_apps tests
   test "UsersApp object gets created and deleted when user creates object and deletes it" do
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