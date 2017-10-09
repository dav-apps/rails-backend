require 'test_helper'

class AuthMethodsTest < ActionDispatch::IntegrationTest
   
   # Login tests
   test "can login" do
      save_users_and_devs
      
      get "/v1/users/login?email=sherlock@web.de&password=sherlocked&auth=" + generate_auth_token(devs(:sherlock))
      
      assert_response :success
   end
   
   test "can't login without email" do
      save_users_and_devs
      
      get "/v1/users/login?password=sherlocked&auth=" + generate_auth_token(devs(:sherlock))
      
      assert_response 400
   end
   
   test "can't login without password" do
      save_users_and_devs
      
      get "/v1/users/login?email=sherlock@web.de&auth=" + generate_auth_token(devs(:sherlock))
      
      assert_response 400
   end
   
   test "can't login without auth" do
      save_users_and_devs
      
      get "/v1/users/login?email=sherlock@web.de&password=sherlocked"
      
      assert_response 401
   end
   
   test "can login without being the dev" do
      save_users_and_devs
      
      get "/v1/users/login?email=sherlock@web.de&password=sherlocked&auth=" + generate_auth_token(devs(:matt))
      
      assert_response 200
   end
   
   test "can't login without being confirmed" do
      save_users_and_devs
      
      matt = users(:matt)
      matt.confirmed = false
      matt.save
      
      get "/v1/users/login?email=matt@test.de&password=schachmatt&auth=" + generate_auth_token(devs(:matt))
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"][0][0], 1202)
   end
   
   test "can't login with an incorrect password" do
      save_users_and_devs
      
      get "/v1/users/login?email=matt@test.de&password=falschesPassword&auth=" + generate_auth_token(devs(:matt))
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(resp["errors"][0][0], 1201)
   end
   
   test "can't login with an invalid auth token" do
      save_users_and_devs
      
      dev = devs(:matt)
      auth = dev.api_key + "," + Base64.strict_encode64(OpenSSL::HMAC.hexdigest(OpenSSL::Digest.new('sha256'), 
                           dev.secret_key, dev.id.to_s + "," + devs(:sherlock).user_id.to_s + "," + dev.uuid.to_s))
      
      get "/v1/users/login?email=matt@test.de&password=schachmatt&auth=" + auth
      resp = JSON.parse response.body
      
      assert_response 401
      assert_same(resp["errors"][0][0], 1101)
   end
   
   test "Dev does not exist in login" do
      save_users_and_devs
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      matt = users(:matt)
      matt.save
      
      sherlock = devs(:sherlock)
      sherlock.destroy!
      
      get "/v1/users/login?email=matt@test.de&password=schachmatt&auth=" + sherlock_auth_token
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(resp["errors"][0][0], 2802)
   end
   
   # Data access tests
   #test "can access only own table data" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
   #   
   #   get "/v1/apps/table?app_id=#{apps(:Cards).id}&table_name=Card&jwt=" + matts_jwt
   #   entries = (JSON.parse response.body)["table"]["entries"].to_a
   #   
   #   # Check the id of each entry and make sure it belongs to the user
   #   entries.each do |entry|
   #      assert_same(entry["user_id"], matt.id)
   #   end
   #end
   
   #test "can access only own table data as a dev" do
   #   save_users_and_devs
   #   
   #   sherlock = users(:sherlock)
   #   
   #   sherlocks_jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]
   #   
   #   get "/v1/apps/table?app_id=#{apps(:Cards).id}&table_name=Card&jwt=" + sherlocks_jwt
   #   entries = (JSON.parse response.body)["table"]["entries"]
   #   
   #   # Check the id of each entry and make sure it belongs to the user
   #   entries.each do |entry|
   #      assert_same(entry["user_id"], sherlock.id)
   #   end
   #end
   
   #test "can't access table data of apps of other devs" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   get "/v1/apps/table?app_id=#{apps(:Cards).id}&table_name=Card&jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can access the own apps" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   get "/v1/apps/app/#{apps(:TestApp).id}?jwt=" + matts_jwt
   #   
   #   assert_response 200
   #end
   
   #test "can't access the apps of another dev" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   get "/v1/apps/app/#{apps(:Cards).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can delete a table of an own app from the website" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
   #   
   #   delete "/v1/apps/table/#{tables(:card).id}?jwt=" + matts_jwt
   #   
   #   assert_response 200
   #end
   
   #test "can't delete a table of an app of another user from the website" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
   #   
   #   delete "/v1/apps/table/#{tables(:note).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can't delete a table from outside the website" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   delete "/v1/apps/table/#{tables(:note).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can't delete an app from outside the website" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   delete "/v1/apps/app/#{apps(:Cards).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can't delete a dev from outside the website" do
   #   save_users_and_devs
   #end
   
   #test "can't delete the table of another dev" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   delete "/v1/apps/table/#{tables(:card).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can't delete the app of another dev" do
   #   save_users_and_devs
   #   
   #   matt = users(:matt)
   #   matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
   #   
   #   delete "/v1/apps/app/#{apps(:Cards).id}?jwt=" + matts_jwt
   #   resp = JSON.parse response.body
   #   
   #   assert_response 403
   #   assert_same(resp["errors"][0][0], 1102)
   #end
   
   #test "can't delete another dev" do
   #   save_users_and_devs
   #end
   
   #test "can't delete another user" do
   #   save_users_and_devs
   #end
   
   
   
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
