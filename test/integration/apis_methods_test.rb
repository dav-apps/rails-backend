require 'test_helper'

class ApisMethodsTest < ActionDispatch::IntegrationTest
	setup do
      save_users_and_devs
	end
	
	# Tests for create_api
	test "Missing fields in create_api" do
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create api without content type json" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create api with invalid jwt" do
		jwt = "asdpjasdaksd"
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create api from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:matt)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create api without name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2111, resp["errors"][0][0])
	end

	test "Can't create api with too short name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "A"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2203, resp["errors"][0][0])
	end

	test "Can't create api with too long name" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: "A" * 120}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2303, resp["errors"][0][0])
	end

	test "Can create api" do
		matt = users(:matt)
		jwt = (JSON.parse login_user(matt, "schachmatt", devs(:sherlock)).body)["jwt"]
		app = apps(:TestApp)
		name = "Test API"

		post "/v1/apps/app/#{app.id}/api", 
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {name: name}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		assert_equal(app.id, resp["app_id"])
		assert_equal(name, resp["name"])
	end
	# End tests for create_api
end