require 'test_helper'

class AnalyticsMethodsTest < ActionDispatch::IntegrationTest
   setup do
      save_users_and_devs
   end
   
	# create_event_log tests
	test "Missing fields in create_event_log" do
		post "/v1/analytics/event", headers: {'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2118, resp["errors"][0][0])
		assert_equal(2110, resp["errors"][1][0])
		assert_equal(2111, resp["errors"][2][0])
		assert_equal(2128, resp["errors"][3][0])
		assert_equal(2129, resp["errors"][4][0])
		assert_equal(2130, resp["errors"][5][0])
		assert_equal(2131, resp["errors"][6][0])
	end

	test "Can't create event log without content type json" do
		post "/v1/analytics/event"
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create event log for the event of another dev" do
		api_key = devs(:sherlock).api_key
		app_id = apps(:TestApp).id
		name = events(:LoginMobile).name
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create event log for event of dev that does not exist" do
		api_key = "blablabla"
		app_id = apps(:TestApp).id
		name = events(:Login).name
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2802, resp["errors"][0][0])
	end

	test "Can't create event log for app that does not exist" do
		api_key = devs(:sherlock).api_key
		app_id = -123
		name = events(:OpenApp).name
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2803, resp["errors"][0][0])
	end

	test "Can't create event by creating event log with too long name" do
		api_key = devs(:sherlock).api_key
		app_id = apps(:Cards).id
		name = "NewTestEventBlablablablablabla"
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
	end

	test "Can't create event by creating event log with too short name" do
		api_key = devs(:sherlock).api_key
		app_id = apps(:Cards).id
		name = "A"
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
	end

	test "Can create event by creating event log" do
		api_key = devs(:sherlock).api_key
		app_id = apps(:Cards).id
		name = "NewTestEvent"
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 201

		event = Event.find_by_id(resp["event_id"])
		assert_not_nil(event)
	end

	test "Can create event log" do
		api_key = devs(:sherlock).api_key
		app_id = apps(:Cards).id
		name = events(:OpenApp).name
		browser_name = "Microsoft Edge"
		browser_version = "80"
		os_name = "Windows"
		os_version = "10"
		country = "DE"

		post "/v1/analytics/event",
			headers: {'Content-Type': 'application/json'},
			params: {api_key: api_key, app_id: app_id, name: name, browser_name: browser_name, browser_version: browser_version, os_name: os_name, os_version: os_version, country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
	end
   # End create_event_log tests
   
	# get_event tests
	test "Missing fields in get_event" do
		get "/v1/analytics/event/1"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get event from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		event = events(:Login)

		get "/v1/analytics/event/#{event.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get event of the app of another dev" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		event = events(:OpenApp)

		get "/v1/analytics/event/#{event.id}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get event with the log summaries of the last month" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

		event = events(:Login)
		summary = standard_event_summaries(:LoginSummaryLastMonth)

		os_count1 = event_summary_os_counts(:LoginSummaryLastMonthOsCount1)
		os_count2 = event_summary_os_counts(:LoginSummaryLastMonthOsCount2)

		browser_count1 = event_summary_browser_counts(:LoginSummaryLastMonthBrowserCount2)
		browser_count2 = event_summary_browser_counts(:LoginSummaryLastMonthBrowserCount1)
		
		country_count1 = event_summary_country_counts(:LoginSummaryLastMonthCountryCount2)
		country_count2 = event_summary_country_counts(:LoginSummaryLastMonthCountryCount1)

		get "/v1/analytics/event/#{event.id}?period=2", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(event.id, resp["id"])
		assert_equal(event.app_id, resp["app_id"])
		assert_equal(event.name, resp["name"])
		assert_equal(summary.period, resp["period"])

		assert_equal(summary.time, resp["summaries"][0]["time"])
		assert_equal(summary.total, resp["summaries"][0]["total"])

		assert_equal(os_count1.name, resp["summaries"][0]["os"][0]["name"])
		assert_equal(os_count1.version, resp["summaries"][0]["os"][0]["version"])
		assert_equal(os_count1.count, resp["summaries"][0]["os"][0]["count"])

		assert_equal(os_count2.name, resp["summaries"][0]["os"][1]["name"])
		assert_equal(os_count2.version, resp["summaries"][0]["os"][1]["version"])
		assert_equal(os_count2.count, resp["summaries"][0]["os"][1]["count"])

		assert_equal(browser_count1.name, resp["summaries"][0]["browser"][0]["name"])
		assert_equal(browser_count1.version, resp["summaries"][0]["browser"][0]["version"])
		assert_equal(browser_count1.count, resp["summaries"][0]["browser"][0]["count"])

		assert_equal(browser_count2.name, resp["summaries"][0]["browser"][1]["name"])
		assert_equal(browser_count2.version, resp["summaries"][0]["browser"][1]["version"])
		assert_equal(browser_count2.count, resp["summaries"][0]["browser"][1]["count"])

		assert_equal(country_count1.country, resp["summaries"][0]["country"][0]["country"])
		assert_equal(country_count1.count, resp["summaries"][0]["country"][0]["count"])

		assert_equal(country_count2.country, resp["summaries"][0]["country"][1]["country"])
		assert_equal(country_count2.count, resp["summaries"][0]["country"][1]["count"])
	end

	test "Can get event with the log summaries within specified timeframe" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		start_timestamp = DateTime.parse("2018-06-05T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2018-06-15T00:00:00.000Z").to_i

		event = events(:Login)
		summary = standard_event_summaries(:LoginSummaryDay)

		os_count1 = event_summary_os_counts(:LoginSummaryDayOsCount1)
		os_count2 = event_summary_os_counts(:LoginSummaryDayOsCount2)

		browser_count1 = event_summary_browser_counts(:LoginSummaryDayBrowserCount1)
		browser_count2 = event_summary_browser_counts(:LoginSummaryDayBrowserCount2)

		country_count1 = event_summary_country_counts(:LoginSummaryDayCountryCount1)
		country_count2 = event_summary_country_counts(:LoginSummaryDayCountryCount2)

		get "/v1/analytics/event/#{event.id}?start=#{start_timestamp}&end=#{end_timestamp}", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(event.id, resp["id"])
		assert_equal(event.app_id, resp["app_id"])
		assert_equal(event.name, resp["name"])
		assert_equal(summary.period, resp["period"])

		assert_equal(summary.time, resp["summaries"][0]["time"])
		assert_equal(summary.total, resp["summaries"][0]["total"])

		assert_equal(os_count1.name, resp["summaries"][0]["os"][0]["name"])
		assert_equal(os_count1.version, resp["summaries"][0]["os"][0]["version"])
		assert_equal(os_count1.count, resp["summaries"][0]["os"][0]["count"])

		assert_equal(os_count2.name, resp["summaries"][0]["os"][1]["name"])
		assert_equal(os_count2.version, resp["summaries"][0]["os"][1]["version"])
		assert_equal(os_count2.count, resp["summaries"][0]["os"][1]["count"])

		assert_equal(browser_count1.name, resp["summaries"][0]["browser"][0]["name"])
		assert_equal(browser_count1.version, resp["summaries"][0]["browser"][0]["version"])
		assert_equal(browser_count1.count, resp["summaries"][0]["browser"][0]["count"])

		assert_equal(browser_count2.name, resp["summaries"][0]["browser"][1]["name"])
		assert_equal(browser_count2.version, resp["summaries"][0]["browser"][1]["version"])
		assert_equal(browser_count2.count, resp["summaries"][0]["browser"][1]["count"])

		assert_equal(country_count1.country, resp["summaries"][0]["country"][0]["country"])
		assert_equal(country_count1.count, resp["summaries"][0]["country"][0]["count"])

		assert_equal(country_count2.country, resp["summaries"][0]["country"][1]["country"])
		assert_equal(country_count2.count, resp["summaries"][0]["country"][1]["count"])
	end

	test "Can get event with log summaries sorted by hour" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		start_timestamp = DateTime.parse("2018-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2018-06-11T00:00:00.000Z").to_i

		event = events(:Login)
		summary = standard_event_summaries(:LoginSummaryHour)

		os_count1 = event_summary_os_counts(:LoginSummaryHourOsCount1)
		os_count2 = event_summary_os_counts(:LoginSummaryHourOsCount2)

		browser_count1 = event_summary_browser_counts(:LoginSummaryHourBrowserCount2)
		browser_count2 = event_summary_browser_counts(:LoginSummaryHourBrowserCount1)

		country_count1 = event_summary_country_counts(:LoginSummaryHourCountryCount2)
		country_count2 = event_summary_country_counts(:LoginSummaryHourCountryCount1)

		get "/v1/analytics/event/#{event.id}?start=#{start_timestamp}&end=#{end_timestamp}&period=0", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(event.id, resp["id"])
		assert_equal(event.app_id, resp["app_id"])
		assert_equal(event.name, resp["name"])
		assert_equal(summary.period, resp["period"])

		assert_equal(summary.time, resp["summaries"][0]["time"])
		assert_equal(summary.total, resp["summaries"][0]["total"])

		assert_equal(os_count1.name, resp["summaries"][0]["os"][0]["name"])
		assert_equal(os_count1.version, resp["summaries"][0]["os"][0]["version"])
		assert_equal(os_count1.count, resp["summaries"][0]["os"][0]["count"])

		assert_equal(os_count2.name, resp["summaries"][0]["os"][1]["name"])
		assert_equal(os_count2.version, resp["summaries"][0]["os"][1]["version"])
		assert_equal(os_count2.count, resp["summaries"][0]["os"][1]["count"])

		assert_equal(browser_count1.name, resp["summaries"][0]["browser"][0]["name"])
		assert_equal(browser_count1.version, resp["summaries"][0]["browser"][0]["version"])
		assert_equal(browser_count1.count, resp["summaries"][0]["browser"][0]["count"])

		assert_equal(browser_count2.name, resp["summaries"][0]["browser"][1]["name"])
		assert_equal(browser_count2.version, resp["summaries"][0]["browser"][1]["version"])
		assert_equal(browser_count2.count, resp["summaries"][0]["browser"][1]["count"])

		assert_equal(country_count1.country, resp["summaries"][0]["country"][0]["country"])
		assert_equal(country_count1.count, resp["summaries"][0]["country"][0]["count"])

		assert_equal(country_count2.country, resp["summaries"][0]["country"][1]["country"])
		assert_equal(country_count2.count, resp["summaries"][0]["country"][1]["count"])
	end

	test "Can get event with log summaries sorted by month" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		start_timestamp = DateTime.parse("2018-04-20T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2018-05-02T00:00:00.000Z").to_i

		event = events(:Login)
		summary = standard_event_summaries(:LoginSummaryMonth)

		os_count1 = event_summary_os_counts(:LoginSummaryMonthOsCount1)
		os_count2 = event_summary_os_counts(:LoginSummaryMonthOsCount2)

		browser_count1 = event_summary_browser_counts(:LoginSummaryMonthBrowserCount3)
		browser_count2 = event_summary_browser_counts(:LoginSummaryMonthBrowserCount1)
		browser_count3 = event_summary_browser_counts(:LoginSummaryMonthBrowserCount2)

		country_count1 = event_summary_country_counts(:LoginSummaryMonthCountryCount1)
		country_count2 = event_summary_country_counts(:LoginSummaryMonthCountryCount2)

		get "/v1/analytics/event/#{event.id}?start=#{start_timestamp}&end=#{end_timestamp}&period=2", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(event.id, resp["id"])
		assert_equal(event.app_id, resp["app_id"])
		assert_equal(event.name, resp["name"])
		assert_equal(summary.period, resp["period"])

		assert_equal(summary.time, resp["summaries"][0]["time"])
		assert_equal(summary.total, resp["summaries"][0]["total"])

		assert_equal(os_count1.name, resp["summaries"][0]["os"][0]["name"])
		assert_equal(os_count1.version, resp["summaries"][0]["os"][0]["version"])
		assert_equal(os_count1.count, resp["summaries"][0]["os"][0]["count"])

		assert_equal(os_count2.name, resp["summaries"][0]["os"][1]["name"])
		assert_equal(os_count2.version, resp["summaries"][0]["os"][1]["version"])
		assert_equal(os_count2.count, resp["summaries"][0]["os"][1]["count"])

		assert_equal(browser_count1.name, resp["summaries"][0]["browser"][0]["name"])
		assert_equal(browser_count1.version, resp["summaries"][0]["browser"][0]["version"])
		assert_equal(browser_count1.count, resp["summaries"][0]["browser"][0]["count"])

		assert_equal(browser_count2.name, resp["summaries"][0]["browser"][1]["name"])
		assert_equal(browser_count2.version, resp["summaries"][0]["browser"][1]["version"])
		assert_equal(browser_count2.count, resp["summaries"][0]["browser"][1]["count"])

		assert_equal(browser_count3.name, resp["summaries"][0]["browser"][2]["name"])
		assert_equal(browser_count3.version, resp["summaries"][0]["browser"][2]["version"])
		assert_equal(browser_count3.count, resp["summaries"][0]["browser"][2]["count"])

		assert_equal(country_count1.country, resp["summaries"][0]["country"][0]["country"])
		assert_equal(country_count1.count, resp["summaries"][0]["country"][0]["count"])

		assert_equal(country_count2.country, resp["summaries"][0]["country"][1]["country"])
		assert_equal(country_count2.count, resp["summaries"][0]["country"][1]["count"])
	end

	test "Can get event with log summaries sorted by year" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		start_timestamp = DateTime.parse("2017-12-30T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2018-01-02T00:00:00.000Z").to_i

		event = events(:Login)
		summary = standard_event_summaries(:LoginSummaryYear)

		os_count1 = event_summary_os_counts(:LoginSummaryYearOsCount2)
		os_count2 = event_summary_os_counts(:LoginSummaryYearOsCount1)
		os_count3 = event_summary_os_counts(:LoginSummaryYearOsCount3)

		browser_count1 = event_summary_browser_counts(:LoginSummaryYearBrowserCount2)
		browser_count2 = event_summary_browser_counts(:LoginSummaryYearBrowserCount1)
		browser_count3 = event_summary_browser_counts(:LoginSummaryYearBrowserCount5)
		browser_count4 = event_summary_browser_counts(:LoginSummaryYearBrowserCount4)
		browser_count5 = event_summary_browser_counts(:LoginSummaryYearBrowserCount3)

		country_count1 = event_summary_country_counts(:LoginSummaryYearCountryCount2)
		country_count2 = event_summary_country_counts(:LoginSummaryYearCountryCount1)
		country_count3 = event_summary_country_counts(:LoginSummaryYearCountryCount3)

		get "/v1/analytics/event/#{event.id}?start=#{start_timestamp}&end=#{end_timestamp}&period=3", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(event.id, resp["id"])
		assert_equal(event.app_id, resp["app_id"])
		assert_equal(event.name, resp["name"])
		assert_equal(summary.period, resp["period"])

		assert_equal(summary.time, resp["summaries"][0]["time"])
		assert_equal(summary.total, resp["summaries"][0]["total"])

		assert_equal(os_count1.name, resp["summaries"][0]["os"][0]["name"])
		assert_equal(os_count1.version, resp["summaries"][0]["os"][0]["version"])
		assert_equal(os_count1.count, resp["summaries"][0]["os"][0]["count"])

		assert_equal(os_count2.name, resp["summaries"][0]["os"][1]["name"])
		assert_equal(os_count2.version, resp["summaries"][0]["os"][1]["version"])
		assert_equal(os_count2.count, resp["summaries"][0]["os"][1]["count"])

		assert_equal(os_count3.name, resp["summaries"][0]["os"][2]["name"])
		assert_equal(os_count3.version, resp["summaries"][0]["os"][2]["version"])
		assert_equal(os_count3.count, resp["summaries"][0]["os"][2]["count"])

		assert_equal(browser_count1.name, resp["summaries"][0]["browser"][0]["name"])
		assert_equal(browser_count1.version, resp["summaries"][0]["browser"][0]["version"])
		assert_equal(browser_count1.count, resp["summaries"][0]["browser"][0]["count"])

		assert_equal(browser_count2.name, resp["summaries"][0]["browser"][1]["name"])
		assert_equal(browser_count2.version, resp["summaries"][0]["browser"][1]["version"])
		assert_equal(browser_count2.count, resp["summaries"][0]["browser"][1]["count"])

		assert_equal(browser_count3.name, resp["summaries"][0]["browser"][2]["name"])
		assert_equal(browser_count3.version, resp["summaries"][0]["browser"][2]["version"])
		assert_equal(browser_count3.count, resp["summaries"][0]["browser"][2]["count"])

		assert_equal(browser_count4.name, resp["summaries"][0]["browser"][3]["name"])
		assert_equal(browser_count4.version, resp["summaries"][0]["browser"][3]["version"])
		assert_equal(browser_count4.count, resp["summaries"][0]["browser"][3]["count"])

		assert_equal(browser_count5.name, resp["summaries"][0]["browser"][4]["name"])
		assert_equal(browser_count5.version, resp["summaries"][0]["browser"][4]["version"])
		assert_equal(browser_count5.count, resp["summaries"][0]["browser"][4]["count"])

		assert_equal(country_count1.country, resp["summaries"][0]["country"][0]["country"])
		assert_equal(country_count1.count, resp["summaries"][0]["country"][0]["count"])

		assert_equal(country_count2.country, resp["summaries"][0]["country"][1]["country"])
		assert_equal(country_count2.count, resp["summaries"][0]["country"][1]["count"])

		assert_equal(country_count3.country, resp["summaries"][0]["country"][2]["country"])
		assert_equal(country_count3.count, resp["summaries"][0]["country"][2]["count"])
	end
   # End get_event tests

   # get_event_by_name tests
   test "Missing fields in get_event_by_name" do
      get "/v1/analytics/event"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
      assert_equal(2110, resp["errors"][1][0])
      assert_equal(2111, resp["errors"][2][0])
   end

   test "get_event_by_name returns the log summaries of an event by name from within the last month" do
      matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		# Update the event summaries with new dates
		first_event_summary = event_summaries(:LoginSummaryDay1)
		second_event_summary = event_summaries(:LoginSummaryDay2)
		first_event_summary.time = Time.now - 2.days
		second_event_summary.time = Time.now - 10.days
		first_event_summary.save
		second_event_summary.save
      
      get "/v1/analytics/event?name=#{events(:Login).name}&app_id=#{events(:Login).app_id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(event_summaries(:LoginSummaryDay1).time.to_i, DateTime.parse(resp["logs"][0]["time"]).to_i)
      assert_equal(event_summaries(:LoginSummaryDay1).total, resp["logs"][0]["total"])

      # First event summary; first property count
      assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount1).name, resp["logs"][0]["properties"][0]["name"])
      assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount1).value, resp["logs"][0]["properties"][0]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount1).count, resp["logs"][0]["properties"][0]["count"])

      # First event summary; second property count
      assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount2).name, resp["logs"][0]["properties"][1]["name"])
      assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount2).value, resp["logs"][0]["properties"][1]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryDay1PropertyCount2).count, resp["logs"][0]["properties"][1]["count"])
		
		# Second event summary; first property count
		assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).name, resp["logs"][1]["properties"][0]["name"])
      assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).value, resp["logs"][1]["properties"][0]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).count, resp["logs"][1]["properties"][0]["count"])
   end

   test "get_event_by_name returns the event logs of the specified timeframe" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      start_timestamp = 1529020800  # 15.6.2018
      end_timestamp = 1531612800    # 15.7.2018
      login_event = events(:Login)

      get "/v1/analytics/event?app_id=#{login_event.app_id}&name=#{login_event.name}&start=#{start_timestamp}&end=#{end_timestamp}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 200

		# Only LoginSummaryDay2 should be returned
      assert_equal(1, resp["logs"].length)
		assert_equal(event_summaries(:LoginSummaryDay2).time.to_i, DateTime.parse(resp["logs"][0]["time"]).to_i)
      assert_equal(event_summaries(:LoginSummaryDay2).total, resp["logs"][0]["total"])

		# First property count
		assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).name, resp["logs"][0]["properties"][0]["name"])
      assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).value, resp["logs"][0]["properties"][0]["value"])
      assert_equal(event_summary_property_counts(:LoginSummaryDay2PropertyCount1).count, resp["logs"][0]["properties"][0]["count"])
	end
	
	test "get_event_by_name returns the log summaries of the given sort" do
		matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		login_event = events(:Login)

		# Update the event summary with a new date
		event_summary = event_summaries(:LoginSummaryMonth)
		event_summary.time = Time.now - 2.days
		event_summary.save
      
      get "/v1/analytics/event?app_id=#{login_event.app_id}&name=#{login_event.name}&sort=month", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body
		
		assert_response 200
      assert_equal(event_summaries(:LoginSummaryMonth).time.to_i, DateTime.parse(resp["logs"][0]["time"]).to_i)
		assert_equal(event_summaries(:LoginSummaryMonth).total, resp["logs"][0]["total"])
		
		# Second property count
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount2).name, resp["logs"][0]["properties"][0]["name"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount2).value, resp["logs"][0]["properties"][0]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount2).count, resp["logs"][0]["properties"][0]["count"])

		# First property count
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount1).name, resp["logs"][0]["properties"][1]["name"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount1).value, resp["logs"][0]["properties"][1]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount1).count, resp["logs"][0]["properties"][1]["count"])

		# Fourth property count
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount4).name, resp["logs"][0]["properties"][2]["name"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount4).value, resp["logs"][0]["properties"][2]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount4).count, resp["logs"][0]["properties"][2]["count"])

		# Third property count
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount3).name, resp["logs"][0]["properties"][3]["name"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount3).value, resp["logs"][0]["properties"][3]["value"])
		assert_equal(event_summary_property_counts(:LoginSummaryMonthPropertyCount3).count, resp["logs"][0]["properties"][3]["count"])
	end

   test "get_event_by_name can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      get "/v1/analytics/event?name=#{events(:Login).name}&app_id=#{events(:Login).app_id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "get_event_by_name can't return the event of the app of another dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      get "/v1/analytics/event?name=#{events(:CreateCard).name}&app_id=#{events(:CreateCard).app_id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   # End get_event_by_name tests
   
   # update_event tests
   test "Missing fields in update_event" do
      put "/v1/analytics/event/#{events(:CreateCard).id}"
      resp = JSON.parse response.body
      
      assert(response.status == 400 || response.status ==  401)
      assert_equal(2102, resp["errors"][0][0])
   end
   
   test "Can't use another content type but json in update_event" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/auth/user", 
				params: {name: "test"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/xml'}
      resp = JSON.parse response.body
      
      assert_response 415
      assert_equal(1104, resp["errors"][0][0])
   end
   
   test "update_event can't be called from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}", 
				params: {name: "test"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update events that don't belong to the dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login2).id}", 
				params: {name: "newname"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't update events that belong to the first dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:CreateCard).id}", 
				params: {name: "newname"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can get the properties of the event after updating" do
      new_name = "newname"
      
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}", 
				params: {name: new_name}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 200
      assert_equal(events(:Login).id, resp["id"])
      assert_equal(new_name, resp["name"])
   end
   
   test "Can't update an event with too long name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}", 
				params: {name: "#{'n' * 30}"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2303, resp["errors"][0][0])
   end
   
   test "Can't update an event with too short name" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}", 
				params: {name: "n"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2203, resp["errors"][0][0])
   end
   
   test "Can't update an event with name that's already taken" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      put "/v1/analytics/event/#{events(:Login).id}", 
				params: {name: "login_mobile"}.to_json,
            headers: {'Authorization' => jwt, 'Content-Type' => 'application/json'}
      resp = JSON.parse response.body
      
      assert_response 400
      assert_equal(2703, resp["errors"][0][0])
   end
   # End update_event tests
   
   # delete_event tests
   test "Can't delete events of the apps of other devs" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login2).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:Login).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can't delete events of apps of the first dev" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      
      delete "/v1/analytics/event/#{events(:OpenApp).id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body
      
      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end
   
   test "Can delete the events of own apps" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
      event_id = events(:Login).id
      
      delete "/v1/analytics/event/#{event_id}", headers: {'Authorization' => jwt}
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
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get app from outside the website" do
      app = apps(:TestApp)
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't get app of another dev" do
      app = apps(:Cards)
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't get app that does not exist" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/app/2", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 404
      assert_equal(2803, resp["errors"][0][0])
   end

   test "Can get app" do
      app = apps(:Cards)
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/app/#{app.id}", headers: {'Authorization' => jwt}

      assert_response 200
   end
   # End get_app tests

   # get_users tests
   test "Missing fields in get_users" do
      get "/v1/analytics/users"
      resp = JSON.parse response.body

      assert_response 401
      assert_equal(2102, resp["errors"][0][0])
   end

   test "Can't get users from outside the website" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]

      get "/v1/analytics/users", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can't get users as another user but the first one" do
      matt = users(:matt)
      jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/users", headers: {'Authorization' => jwt}
      resp = JSON.parse response.body

      assert_response 403
      assert_equal(1102, resp["errors"][0][0])
   end

   test "Can get users" do
      sherlock = users(:sherlock)
      jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

      get "/v1/analytics/users", headers: {'Authorization' => jwt}

      assert_response 200
   end
	# End get_users tests
	
	# get_active_users tests
	test "Missing fields in get_active_users" do
		get "/v1/analytics/active_users"
		resp = JSON.parse response.body

		assert_response 401
      assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get active users from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		
		get "/v1/analytics/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get active users as another user but the first one" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		
		get "/v1/analytics/active_users", headers: {'Authorization' => jwt}
		resp = JSON.parse response.body

		assert_response 403
      assert_equal(1102, resp["errors"][0][0])
	end

	test "Can get active users" do
		matt = users(:matt)
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

		# Create active users
		first_active_user = ActiveUser.create(time: (Time.now - 1.days).beginning_of_day, 
										count_daily: 3, 
										count_monthly: 9,
										count_yearly: 14)
		second_active_user = ActiveUser.create(time: (Time.now - 3.days).beginning_of_day,
										count_daily: 5,
										count_monthly: 8,
										count_yearly: 21)
		
		get "/v1/analytics/active_users", headers: {'Authorization' => jwt}
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

	test "Can get active users in the specified timeframe" do
		matt = users(:matt)
		sherlock = users(:sherlock)
		jwt = (JSON.parse login_user(sherlock, "sherlocked", devs(:sherlock)).body)["jwt"]

		start_timestamp = DateTime.parse("2019-06-09T00:00:00.000Z").to_i
		end_timestamp = DateTime.parse("2019-06-12T00:00:00.000Z").to_i
		first_active_user = active_users(:first_active_user)
		second_active_user = active_users(:second_active_user)

		get "/v1/analytics/active_users?start=#{start_timestamp}&end=#{end_timestamp}", headers: {'Authorization' => jwt}
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
	# End get_active_users tests
end