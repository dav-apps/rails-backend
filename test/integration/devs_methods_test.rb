require 'test_helper'

class DevsMethodsTest < ActionDispatch::IntegrationTest

   setup do
      save_users_and_devs
   end
   
   # create_dev tests
   test "Missing fields in create_dev" do
      post "/v1/devs/dev"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(resp["errors"].length, 1)
   end
   
   test "Can't create dev for user that already is a dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 409
      assert_equal(2902, resp["errors"][0][0])
   end
   
   test "Can create dev for user from the website" do
      cato = users(:cato)
      jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 201
   end
   
   test "Can't create dev from outside the website" do
      cato = users(:cato)
      jwt = (JSON.parse login_user(cato, "123456", devs(:matt)).body)["jwt"]
      
      post "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End create_dev tests
   
   # get_dev tests
   test "Can get dev from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(devs(:matt).id, resp["id"])
      assert_not_nil(resp["apps"][0]["id"])
   end
   
   test "Can't get dev from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End get_dev tests
   
   # get_dev_by_api_key tests
   test "Can't get dev by api_key without auth token" do
      get "/v1/devs/dev/#{devs(:matt).api_key}"
      resp = JSON.parse response.body
      
      assert_response 401
      assert_equal(2101, resp["errors"][0][0])
   end
   
   test "Can't get dev by api_key from outside the website" do
      auth = generate_auth_token(devs(:matt))
      get "/v1/devs/dev/#{devs(:matt).api_key}", headers: {'Authorization' => auth}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can get dev by api_key from the website" do
      auth = generate_auth_token(devs(:sherlock))
      get "/v1/devs/dev/#{devs(:matt).api_key}", headers: {'Authorization' => auth}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(devs(:matt).id, resp["id"])
      assert_not_nil(resp["apps"][0]["id"])
   end
   # End get_dev_by_api_key_tests
   
   # delete_dev tests
   test "Can delete dev from the website" do
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can't delete dev if it has apps" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(1107, resp["errors"][0][0])
   end
   
   test "Can't delete dev from outside the website" do
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:matt)).body)["jwt"]
      
      delete "/v1/devs/dev", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End delete_dev tests
   
   # generate_new_keys tests
   test "Can generate new keys from the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs/generate_new_keys", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can't generate new keys from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/devs/generate_new_keys", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End generate_new_keys tests
end