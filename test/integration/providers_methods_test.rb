require 'test_helper'

class ProvidersMethodsTest < ActionDispatch::IntegrationTest
	# create_provider tests
	test "Missing fields in create_provider" do
		post "/v1/provider"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't create provider without content type json" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/provider", headers: {'Authorization': jwt}
		resp = JSON.parse(response.body)

		assert_response 415
		assert_equal(1104, resp["errors"][0][0])
	end

	test "Can't create provider with invalid jwt" do
		post "/v1/provider", headers: {Authorization: 'asdasdasd', 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't create provider from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:matt)).body))["jwt"]

		post "/v1/provider",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {country: "de"}.to_json
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't create provider without country" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/provider", headers: {Authorization: jwt, 'Content-Type': 'application/json'}
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(2138, resp["errors"][0][0])
	end

	test "Can't create provider with unsupported country" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		post "/v1/provider",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {country: "bla"}.to_json
		resp = JSON.parse(response.body)

		assert_response 400
		assert_equal(1116, resp["errors"][0][0])
	end

	test "Can't create provider for user that already has a provider" do
		snicket = users(:snicket)
		jwt = (JSON.parse(login_user(snicket, "vfd", devs(:sherlock)).body))["jwt"]

		post "/v1/provider",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {country: "de"}.to_json
		resp = JSON.parse(response.body)

		assert_response 409
		assert_equal(2910, resp["errors"][0][0])
	end

	test "Can create provider" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]
		country = "US"

		post "/v1/provider",
			headers: {Authorization: jwt, 'Content-Type': 'application/json'},
			params: {country: country}.to_json
		resp = JSON.parse(response.body)

		assert_response 201
		
		# Get the provider and check the account id
		provider = ProviderDelegate.find_by(user_id: matt.id)
		assert_equal(provider.id, matt.id)
		assert_equal(provider.user_id, matt.id)
		assert_equal(provider.stripe_account_id, resp["stripe_account_id"])

		# Get the stripe account
		stripe_account = Stripe::Account.retrieve(provider.stripe_account_id)
		assert_not_nil(stripe_account)
		assert_equal(country, stripe_account.country)

		# Delete the stripe account
		Stripe::Account.delete(provider.stripe_account_id)
	end

	# get_provider tests
	test "Missing fields in get_provider" do
		get "/v1/provider"
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(2102, resp["errors"][0][0])
	end

	test "Can't get provider with invalid jwt" do
		get "/v1/provider", headers: {Authorization: "asdasdasd"}
		resp = JSON.parse(response.body)

		assert_response 401
		assert_equal(1302, resp["errors"][0][0])
	end

	test "Can't get provider from outside the website" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:matt)).body))["jwt"]

		get "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 403
		assert_equal(1102, resp["errors"][0][0])
	end

	test "Can't get provider of user that has no provider" do
		matt = users(:matt)
		jwt = (JSON.parse(login_user(matt, "schachmatt", devs(:sherlock)).body))["jwt"]

		get "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 404
		assert_equal(2817, resp["errors"][0][0])
	end

	test "Can get provider" do
		provider = providers(:snicket)
		snicket = users(:snicket)
		jwt = (JSON.parse(login_user(snicket, "vfd", devs(:sherlock)).body))["jwt"]

		get "/v1/provider", headers: {Authorization: jwt}
		resp = JSON.parse(response.body)

		assert_response 200
		assert_equal(provider.id, resp["id"])
		assert_equal(provider.user_id, resp["user_id"])
		assert_equal(provider.stripe_account_id, resp["stripe_account_id"])
	end
end