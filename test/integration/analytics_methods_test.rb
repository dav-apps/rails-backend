require 'test_helper'

class AnalyticsMethodsTest < ActionDispatch::IntegrationTest

   setup do
      save_users_and_devs
   end
   
   # create_event_log tests
   test "Missing fields in create_event_log" do
      post "/v1/analytics/event"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2118, resp["errors"][0][0])
      assert_same(2111, resp["errors"][1][0])
      assert_same(2110, resp["errors"][2][0])
   end
   
   test "Can't create event with too short event name" do
      api_key = devs(:matt).api_key
      
      post "/v1/analytics/event?api_key=#{api_key}&name=n&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't create event with too long event name" do
      api_key = devs(:matt).api_key
      
      post "/v1/analytics/event?api_key=#{api_key}&name=#{"n"*65100}&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Create new event when event does not yet exist" do
      api_key = devs(:matt).api_key
      
      post "/v1/analytics/event?api_key=#{api_key}&name=NewEvent&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 201
      assert_same(Event.find_by(name: "NewEvent").id, resp["event_id"])
   end

   test "Can't create event log for the event of another dev" do
      api_key = devs(:sherlock).api_key

      post "/v1/analytics/event?api_key=#{api_key}&name=#{events(:LoginMobile).name}&app_id=#{apps(:TestApp).id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can create event log without properties" do
		api_key = devs(:matt).api_key
		name = events(:LoginMobile).name
      
      post "/v1/analytics/event?api_key=#{api_key}&name=#{name}&app_id=#{apps(:TestApp).id}"
		resp = JSON.parse response.body

		assert_response 201
		log = EventLog.find_by_id(resp["id"])
		assert_equal(name, log.event.name)
   end

   test "Can create event log with properties" do
      api_key = devs(:matt).api_key
      name = events(:LoginMobile).name
      firstPropertyName = "test1"
      secondPropertyName = "test2"
      firstPropertyValue = "bla"
      secondPropertyValue = "blabla"
      data = '{"' + firstPropertyName + '": "' + firstPropertyValue + '", 
               "' + secondPropertyName + '": "' + secondPropertyValue + '"}'
      
      post "/v1/analytics/event?api_key=#{api_key}&name=#{name}&app_id=#{apps(:TestApp).id}", data, {"Content-Type" => "application/json"}
      resp = JSON.parse response.body

      assert_response 201
      log = EventLog.find_by_id(resp["id"])
      assert_equal(name, log.event.name)
      assert_equal(firstPropertyName, log.event_log_properties[0].name)
      assert_equal(firstPropertyValue, log.event_log_properties[0].value)
      assert_equal(secondPropertyName, log.event_log_properties[1].name)
      assert_equal(secondPropertyValue, log.event_log_properties[1].value)
   end

   test "Can't create event log with too long property name" do
      api_key = devs(:matt).api_key

      post "/v1/analytics/event?api_key=#{api_key}&name=#{events(:LoginMobile).name}&app_id=#{apps(:TestApp).id}", "{\"#{"n"*240}\":\"test\"}", {"Content-Type" => "application/json"}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2306, resp["errors"][0][0])
   end
   
   test "Can't create event log with too long property value" do
      api_key = devs(:matt).api_key

      post "/v1/analytics/event?api_key=#{api_key}&name=#{events(:LoginMobile).name}&app_id=#{apps(:TestApp).id}", "{\"test\":\"#{"t"*65100}\"}", {"Content-Type" => "application/json"}
      resp = JSON.parse response.body

      assert_response 400
      assert_same(2307, resp["errors"][0][0])
   end

   test "create_event_log with save_country should create a property with the country code" do
      api_key = devs(:matt).api_key
      name = events(:LoginMobile).name

      post "/v1/analytics/event?api_key=#{api_key}&name=#{name}&app_id=#{apps(:TestApp).id}&save_country=true"
      resp = JSON.parse response.body

      assert_response 201
      log = EventLog.find_by_id(resp["id"])
      assert_equal("country", log.event_log_properties[0].name)
   end

   test "create_event_log with save_country and properties should create a property with the country code" do
      api_key = devs(:matt).api_key
      name = events(:LoginMobile).name
      propertyName = "test"
      propertyValue = "blabla"
      data = '{"' + propertyName + '": "' + propertyValue + '"}'

      post "/v1/analytics/event?api_key=#{api_key}&name=#{name}&app_id=#{apps(:TestApp).id}&save_country=true", data, {"Content-Type" => "application/json"}
      resp = JSON.parse response.body

      assert_response 201
      log = EventLog.find_by_id(resp["id"])
      assert_equal(propertyName, log.event_log_properties[0].name)
      assert_equal(propertyValue, log.event_log_properties[0].value)
      assert_equal("country", log.event_log_properties[1].name)
   end

   test "create_event_log should not create a property when the property has no value" do
      api_key = devs(:matt).api_key
      name = events(:LoginMobile).name
      first_property_name = "test"
      second_property_name = "test2"
      data = '{"' + first_property_name + '": "", "' + second_property_name + '": "content"}'

      post "/v1/analytics/event?api_key=#{api_key}&name=#{name}&app_id=#{apps(:TestApp).id}", data, {"Content-Type" => "application/json"}
      resp = JSON.parse response.body

      assert_response 201
      log = EventLog.find_by_id(resp["id"])
      assert_equal(1, log.event_log_properties.count)
      assert_equal(second_property_name, log.event_log_properties.first.name)
   end
   # End create_event_log tests
   
   # get_event tests
   test "Can get all logs and event_log_properties of an event" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(event_logs(:First).id, resp["logs"][0]["id"])
      assert_equal(event_logs(:Second).id, resp["logs"][1]["id"])
      assert_equal(event_log_properties(:LoginFirstEventLogProperty1).value, resp["logs"][0]["properties"][event_log_properties(:LoginFirstEventLogProperty1).name])
      assert_equal(event_log_properties(:LoginFirstEventLogProperty2).value, resp["logs"][0]["properties"][event_log_properties(:LoginFirstEventLogProperty2).name])
      assert_equal(event_log_properties(:LoginSecondEventLogProperty1).value, resp["logs"][1]["properties"][event_log_properties(:LoginSecondEventLogProperty1).name])
      assert_equal(event_log_properties(:LoginSecondEventLogProperty2).value, resp["logs"][1]["properties"][event_log_properties(:LoginSecondEventLogProperty2).name])
   end
   
   test "get_event can't be called from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't get the event of the app of another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event/#{events(:CreateCard).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "get_event returns the event logs of the specified timeframe" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      start_timestamp = 1529020800  # 15.6.2018
      end_timestamp = 1531612800    # 15.7.2018

      get "/v1/analytics/event/#{events(:Login).id}?start=#{start_timestamp}&end=#{end_timestamp}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(1, resp["logs"].length)
      assert_equal(event_logs(:Second).id, resp["logs"][0]["id"])
   end
   # End get_event tests

   # get_event_by_name tests
   test "Missing fields in get_event_by_name" do
      get "/v1/analytics/event"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2111, resp["errors"][0][0])
      assert_same(2110, resp["errors"][1][0])
      assert_same(2102, resp["errors"][2][0])
   end

   test "get_event_by_name can get all logs of an event by name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:Login).name}&app_id=#{events(:Login).app_id}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(event_logs(:First).id, resp["logs"][0]["id"])
      assert_equal(event_logs(:Second).id, resp["logs"][1]["id"])
      assert_equal(event_log_properties(:LoginFirstEventLogProperty1).value, resp["logs"][0]["properties"][event_log_properties(:LoginFirstEventLogProperty1).name])
      assert_equal(event_log_properties(:LoginFirstEventLogProperty2).value, resp["logs"][0]["properties"][event_log_properties(:LoginFirstEventLogProperty2).name])
      assert_equal(event_log_properties(:LoginSecondEventLogProperty1).value, resp["logs"][1]["properties"][event_log_properties(:LoginSecondEventLogProperty1).name])
      assert_equal(event_log_properties(:LoginSecondEventLogProperty2).value, resp["logs"][1]["properties"][event_log_properties(:LoginSecondEventLogProperty2).name])
   end

   test "get_event_by_name can't be called from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:Login).name}&app_id=#{events(:Login).app_id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get the event by name of the app of another dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event?jwt=#{matts_jwt}&name=#{events(:CreateCard).name}&app_id=#{events(:CreateCard).app_id}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "get_event_by_name returns the event logs of the specified timeframe" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      start_timestamp = 1529020800  # 15.6.2018
      end_timestamp = 1531612800    # 15.7.2018
      login_event = events(:Login)

      get "/v1/analytics/event?app_id=#{login_event.app_id}&name=#{login_event.name}&start=#{start_timestamp}&end=#{end_timestamp}&jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(1, resp["logs"].length)
      assert_equal(event_logs(:Second).id, resp["logs"][0]["id"])
   end
   # End get_event_by_name tests
   
   # update_event tests
   test "Missing fields in update_event" do
      put "/v1/analytics/event/#{events(:CreateCard).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_event" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/auth/user?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_same(1104, resp["errors"][0][0])
   end
   
   test "update_event can't be called from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"test\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update events that don't belong to the dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login2).id}?jwt=#{matts_jwt}", "{\"name\":\"newname\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "can't update events that belong to the first dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:CreateCard).id}?jwt=#{matts_jwt}", "{\"name\":\"newname\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can get the properties of the event after updating" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"#{"n"*30}\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2303, resp["errors"][0][0])
   end
   
   test "Can't update an event with too short name" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}", "{\"name\":\"n\"}", {'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_same(2203, resp["errors"][0][0])
   end
   
   test "Can't update an event with name that's already taken" do
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
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login2).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events of apps of the first dev" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:OpenApp).id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end
   
   test "Can delete the events of own apps" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      event_id = events(:Login).id
      
      delete "/v1/analytics/event/#{event_id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body
      
      assert_response 200
      assert_nil(Event.find_by_id(event_id))
   end
   # End delete_event tests

   # get_app tests
   test "Missing fields in get_app" do
      app = apps(:Cards)
      get "/v1/analytics/app/#{app.id}"
      resp = JSON.parse response.body

      assert(response.status == 400 || response.status ==  401)
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can't get app from outside the website" do
      app = apps(:TestApp)
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get app of another dev" do
      app = apps(:Cards)
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get app that does not exist" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/app/2?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 404
      assert_same(2803, resp["errors"][0][0])
   end

   test "Can get app" do
      app = apps(:Cards)
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}?jwt=#{jwt}"

      assert_response 200
   end
   # End get_app tests

   # get_users tests
   test "Missing fields in get_users" do
      get "/v1/analytics/users"
      resp = JSON.parse response.body

      assert_response 401
      assert_same(2102, resp["errors"][0][0])
   end

   test "Can't get users from outside the website" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/users?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can't get users as another user but the first one" do
      matt = users(:matt)
      matts_jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/users?jwt=#{matts_jwt}"
      resp = JSON.parse response.body

      assert_response 403
      assert_same(1102, resp["errors"][0][0])
   end

   test "Can get users" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/users?jwt=#{jwt}"

      assert_response 200
   end
   # End get_users tests
end