require 'test_helper'

class DevsMethodsTest < ActionDispatch::IntegrationTest
   
   # Create_dev tests
   test "Missing fields in create_dev" do
      post "/v1/devs"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(resp["errors"].length, 1)
   end
   
   test "Can't create dev for user that already is a dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2902, resp["errors"][0][0])
   end
   
   test "Can create dev for user from the website" do
      save_users_and_devs
      
      cato = users(:cato)
      jwt = (JSON.parse login_user(cato, "123456", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs?jwt=#{jwt}"
      resp = JSON.parse response.body
      
      assert_response 201
   end
   
   test "Can't create dev from outside the website" do
      save_users_and_devs
      
      cato = users(:cato)
      jwt = (JSON.parse login_user(cato, "123456", devs(:matt)).body)["jwt"]
      
      post "/v1/devs?jwt=#{jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End create_dev tests
   
   # get_dev tests
   test "Can get dev from the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/devs?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can't get dev from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/devs?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End get_dev tests
   
   # delete_dev tests
   test "Can delete dev from the website" do
      save_users_and_devs
      
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/devs?jwt=#{jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can't delete dev if it has apps" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/devs?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(1107, resp["errors"][0][0])
   end
   
   test "Can't delete dev from outside the website" do
      save_users_and_devs
      
      tester2 = users(:tester2)
      jwt = (JSON.parse login_user(tester2, "testpassword", devs(:matt)).body)["jwt"]
      
      delete "/v1/devs?jwt=#{jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End delete_dev tests
   
   # generate_new_keys tests
   test "Can generate new keys from the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      post "/v1/devs/generate_new_keys?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
   end
   
   test "Can't generate new keys from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      post "/v1/devs/generate_new_keys?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End generate_new_keys tests
   
   
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
      
      tester = users(:tester)
      tester.password = "testpassword"
      tester.save
      
      tester2 = users(:tester2)
      tester2.password = "testpassword"
      tester2.save
      
      devs(:dav).save
      devs(:matt).save
      devs(:sherlock).save
      devs(:tester2).save
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