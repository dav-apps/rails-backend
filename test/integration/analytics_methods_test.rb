require 'test_helper'

class AnalyticsMethodsTest < ActionDispatch::IntegrationTest
   
   # create_event_log tests
   test "Missing fields in create_event_log" do
      post "/v1/analytics/event"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2111, resp["errors"][0][0])
      assert_same(2110, resp["errors"][1][0])
      assert_same(2101, resp["errors"][2][0])
   end
   
   test "Can't create event with too short eventname" do
      save_users_and_devs
      
      auth = generate_auth_token(devs(:matt))
      post "/v1/analytics/event?auth=#{auth}&name=n&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't create event with too long eventname" do
      save_users_and_devs
      
      auth = generate_auth_token(devs(:matt))
      post "/v1/analytics/event?auth=#{auth}&name=#{"n"*30}&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Create new event when event does not yet exist" do
      save_users_and_devs
      
      auth = generate_auth_token(devs(:matt))
      post "/v1/analytics/event?auth=#{auth}&name=NewEvent&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(Event.find_by(name: "NewEvent").id, resp["event_id"])
   end
   
   # End create_event tests
   
   
   # get_event tests
   
   test "Can get all logs of an event" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      resp["event"]["logs"].each do |e|
         assert_same(events(:Login).id, e["event_id"])
      end
   end
   
   test "Can get all logs of an event by name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:Login).name}"
      resp = JSON.parse response.body
      
      assert_response 200
      resp["event"]["logs"].each do |e|
         assert_same(events(:Login).id, e["event_id"])
      end
   end
   
   test "get_event can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "get_event_by_name can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:Login).name}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the event of the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:CreateCard).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the event by name of the app of another dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:CreateCard).name}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Missing fields in get_event_by_name" do
      save_users_and_devs
      
      get "/v1/analytics/event"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2111, resp["errors"][0][0])
      assert_same(2102, resp["errors"][1][0])
   end
   # End get_event tests
   
   # update_event tests
   
   test "Missing fields in update_event" do
      put "/v1/analytics/event/#{events(:CreateCard).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_event" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/users?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "update_event can't be called from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update events that don't belong to the dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login2).id}?jwt=#{matts_jwt}", "{\"name\":\"newname\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update events that belong to the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:CreateCard).id}?jwt=#{matts_jwt}", "{\"name\":\"newname\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get the properties of the event after updating" do
      save_users_and_devs
      
      new_name = "newname"
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"#{new_name}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_same(events(:Login).id, resp["id"])
      assert_equal(new_name, resp["name"])
   end
   
   test "Can't update an event with too long name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"#{"n"*30}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Can't update an event with too short name" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"n\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't update an event with name that's already taken" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"login_mobile\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2703, resp["errors"][0][0])
   end
   # End update_event tests
   
   # delete_event tests
   test "Can't delete events of the apps of other devs" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login2).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events from outside the website" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events of apps of the first dev" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:OpenApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can delete the events of own apps" do
      save_users_and_devs
      
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      event_id = events(:Login).id
      
      delete "/v1/analytics/event/#{event_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(Event.find_by_id(event_id))
   end
   
   # End delete_event tests
   
   
   
   
   
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