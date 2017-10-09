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
      
      post "/v1/apps/app?jwt=#{matts_jwt}&name=#{"o"*17}&desc=" + "o"*300
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"].length, 2)
      assert_same(resp["errors"][0][0], 2303)
      assert_same(resp["errors"][1][0], 2304)
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
      assert_same(tables(:note).id, resp["app"]["tables"][0]["id"])
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
   
   # update_app tests
   test "Missing fields in update_app" do
      save_users_and_devs
      
      put "/v1/apps/app/#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 3)
   end
   
   test "User does not exist in update_app" do
      save_users_and_devs
      matt_id = users(:matt).id
      test_app_id = apps(:TestApp).id
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:sherlock)).body)["jwt"]
      users(:matt).destroy!
      
      put "/v1/apps/app/#{test_app_id}?jwt=#{matts_jwt}&name=New Appname&desc=Hello World! This is the new description."
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2801, resp["errors"][0][0])
   end
   
   test "update_app can't be called from outside the website" do
      save_users_and_devs
      
      matts_jwt = (JSON.parse login_user(users(:matt), "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}&name=New Appname&desc=Hello World! This is the new description."
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update an app with too long name and description" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}&name=#{"o"*17}&desc=" + "o"*300
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
      
      put "/v1/apps/app/#{apps(:TestApp).id}?jwt=#{matts_jwt}&name=o&desc=o"
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
      
      put "/v1/apps/app/#{apps(:davApp).id}?jwt=#{matts_jwt}&name=New Name&desc=New description"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(resp["errors"][0][0], 1102)
   end
   
   test "Can't update the app of the first dev as another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/app/#{apps(:Cards).id}?jwt=#{matts_jwt}&name=New Name&desc=New description"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
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
   
   test "can't use another Content-Type but json in create_object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", {"test": "test"}, {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "Table does not exist and gets created when the user is the dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=NewTable&app_id=#{apps(:TestApp).id}", nil, {'Content-Type' => 'application/json'}
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
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"n\":\"v\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't create an object with too long name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/apps/object?jwt=#{matts_jwt}&table_name=#{tables(:note).name}&app_id=#{apps(:TestApp).id}", "{\"#{"n"*30}\":\"#{"n"*202}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2306, resp["errors"][0][0])
      assert_same(2307, resp["errors"][1][0])
   end
   
   test "Can create public object" do
      
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
   
   test "Can get public object" do
      
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
      assert_not_nil(resp["page1"])
      assert_not_nil(resp["page2"])
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
   
   test "Can't update an object with too long name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"n\":\"v\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2206, resp["errors"][0][0])
      assert_same(2207, resp["errors"][1][0])
   end
   
   test "Can't update an object with too short name and value" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/object/#{table_objects(:first).id}?jwt=#{matts_jwt}", "{\"#{"n"*30}\":\"#{"n"*202}\"}", {'Content-Type' => 'application/json'}
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
      assert_not_nil(resp["test"])
   end
   # End update_object tests
   
   # delete_object tests
   test "Can't delete an object when the dev does not own the table and the user does not own the object" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/apps/object/#{table_objects(:fifth).id}?jwt=#{matts_jwt}"
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
      assert_same(apps(:Cards).id, resp["table"]["app_id"])
      resp["table"]["entries"].each do |e|
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
      assert_same(2113, resp["errors"][0][0])
      assert_same(2102, resp["errors"][1][0])
   end
   
   test "update_table can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}&table_name=Test"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update the table of the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:davTable).id}?jwt=#{matts_jwt}&table_name=Test"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't update a table with too long table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}&table_name=#{"n"*30}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2305, resp["errors"][0][0])
   end
   
   test "Can't update a table with too short table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}&table_name=n"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2205, resp["errors"][0][0])
   end
   
   test "Can't update a table with invalid table name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}&table_name=Test Name"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2501, resp["errors"][0][0])
   end
   
   test "Can get the table properties after updating" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:note).id}?jwt=#{matts_jwt}&table_name=TestName"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(tables(:note).id, resp["id"])
   end
   
   test "Can't update a table of the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/apps/table/#{tables(:card).id}?jwt=#{matts_jwt}&table_name=Test"
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
   
   
   
   
   def save_users_and_devs
      dav = users(:dav)
      dav.password = "raspberry"
      dav.save
      
      matt = users(:matt)
      matt.password = "schachmatt"
      matt.save
      
      sherlock = users(:sherlock)
      sherlock.password = "sherlocked"
      sherlock.save
      
      cato = users(:cato)
      cato.password = "123456"
      cato.save
      
      devs(:dav).save
      devs(:matt).save
      devs(:sherlock).save
   end
   
   def login_user(user, password, dev)
      get "/v1/users/login?email=#{user.email}&password=#{password}&auth=" + generate_auth_token(dev)
      response
   end
   
   def generate_auth_token(dev)
      dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), 
                           dev.secret_key, dev.id.to_s + "," + dev.user_id.to_s + "," + dev.uuid.to_s))
   end
end