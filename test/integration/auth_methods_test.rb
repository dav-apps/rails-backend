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
   
   
   # Signup tests
   test "Missing fields in signup" do
      post "/v1/users/signup"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2106, resp["errors"][0][0])
      assert_same(2107, resp["errors"][1][0])
      assert_same(2105, resp["errors"][2][0])
      assert_same(2101, resp["errors"][3][0])
   end
   
   test "Email already taken in signup" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=dav@gmail.com&password=testtest&username=test"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2702, resp["errors"][0][0])
   end
   
   test "Username already taken in signup" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=test@example.com&password=testtest&username=cato"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2701, resp["errors"][0][0])
   end
   
   test "Can't signup with too short username and password" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=test@example.com&password=te&username=t"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2202, resp["errors"][0][0])
      assert_same(2201, resp["errors"][1][0])
   end
   
   test "Can't signup with too long username and password" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=test@example.com&password=#{"n"*50}&username=#{"n"*30}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2302, resp["errors"][0][0])
      assert_same(2301, resp["errors"][1][0])
   end
   
   test "Can't signup with invalid email" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=testexample&password=testtest&username=testuser"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2401, resp["errors"][0][0])
   end
   
   test "Can't signup users as another dev except the first dev" do
      save_users_and_devs
      
      matts_auth_token = generate_auth_token(devs(:matt))
      
      post "/v1/users/signup?auth=#{matts_auth_token}&email=testexample&password=testtest&username=testuser"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   # End signup tests
   
   # get_user tests
   test "Can't get user when the requested user is not the current user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/users/#{users(:sherlock).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get user when the requested user is the current user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/users/#{matt.id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(matt.id, resp["id"])
   end
   
   test "User does not exist in get_user" do
      save_users_and_devs
      
      matt = users(:matt)
      matt_id = matt.id
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      matt.destroy!
      
      get "/v1/users/#{matt_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2801, resp["errors"][0][0])
   end
   # End get_user tests
   
   # update_user tests
   test "Can't use another content type but json in update_user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"test\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "Can't update user from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"test\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
      
   test "Can't update user with invalid email" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"email\":\"testemail\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2401, resp["errors"][0][0])
   end
   
   test "Can't update user with too short username" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"username\":\"d\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2201, resp["errors"][0][0])
   end
   
   test "Can't update user with too long username" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"username\":\"#{"d"*30}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2301, resp["errors"][0][0])
   end
   
   test "Can't update user with username that's already taken" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"username\":\"cato\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2701, resp["errors"][0][0])
   end
   
   test "Can't update user with too short password" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"password\":\"c\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2202, resp["errors"][0][0])
   end
   
   test "Can't update user with too long password" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"password\":\"#{"n"*40}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2302, resp["errors"][0][0])
   end
   
   test "New password email gets send in update_user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"password\":\"testpassword\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      email = ActionMailer::Base.deliveries.last
      
      assert_response 200
      assert_not_nil(email)
      assert_equal(matt.email, email.to[0])
   end
   
   test "New email email gets send in update_user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"email\":\"test14@example.com\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      email = ActionMailer::Base.deliveries.last
      
      assert_response 200
      assert_not_nil(email)
      assert_equal(resp["new_email"], email.to[0])
   end
   
   test "username and avatar_file_extension gets changed in update_user" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"username\":\"newtestuser\",\"avatar_file_extension\": \".jpg\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      matt = User.find_by_id(matt.id)
      
      assert_response 200
      assert_equal(resp["username"], matt.username)
      assert_equal(resp["avatar_file_extension"], matt.avatar_file_extension)
   end
   
   test "Can update email and password of user at the same time" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"email\":\"newemail@test.com\",\"password\": \"hello password\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      matt = User.find_by_id(matt.id)
      
      assert_response 200
      assert_equal(resp["new_email"], matt.new_email)
      assert_equal(resp["new_password"], matt.new_password)
   end
   # End update_user tests
   
   # delete_user tests
   test "Can't delete user from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/users?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "User gets deleted" do
      save_users_and_devs
      
      matt = users(:matt)
      matt_id = matt.id
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/users?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(User.find_by_id(matt_id))
   end
   # End delete_user tests
   
   # confirm_user tests
   test "Can confirm new user" do
      save_users_and_devs
      
      sherlock_auth_token = generate_auth_token(devs(:sherlock))
      
      post "/v1/users/signup?auth=#{sherlock_auth_token}&email=test@example.com&password=testtest&username=testuser"
      resp = JSON.parse response.body
      
      assert_response 201
      
      new_user = User.find_by_id(resp["id"])
      
      new_users_confirmation_token = User.find_by_id(resp["id"]).email_confirmation_token
      post "/v1/users/#{new_user.id}/confirm?email_confirmation_token=#{new_user.email_confirmation_token}"
      
      assert_response 200
      assert(User.find_by_id(new_user.id).confirmed)
   end
   
   test "Can't confirm user without email_confirmation_token" do
      save_users_and_devs
      
      tester = users(:tester)
      
      post "/v1/users/#{tester.id}/confirm"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2108, resp["errors"][0][0])
   end
   
   test "Can't confirm new user with invalid email_confirmation_token" do
      save_users_and_devs
      
      tester = users(:tester)
      
      post "/v1/users/#{tester.id}/confirm?email_confirmation_token=aiosdashdashas8dg"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(1204, resp["errors"][0][0])
   end
   
   test "Check if user is already confirmed" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_confirmation_token = "testconfirmationtoken"
      
      post "/v1/users/#{matt.id}/confirm?email_confirmation_token=#{matts_confirmation_token}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(1106, resp["errors"][0][0])
   end
   
   # End confirm_user tests
   
   
   
   
   
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
